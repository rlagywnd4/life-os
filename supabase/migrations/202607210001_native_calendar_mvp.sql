create type public.calendar_event_category as enum ('GENERAL', 'APPOINTMENT', 'TRAVEL', 'MILESTONE');

alter table public.action_items
  add column scheduled_time time,
  add column due_date date;

alter table public.daily_plans
  add column available_minutes integer check (available_minutes is null or available_minutes between 0 and 1440);

create table public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  event_date date not null,
  start_time time,
  end_time time,
  is_all_day boolean not null default false,
  category public.calendar_event_category not null default 'GENERAL',
  location text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (is_all_day or start_time is not null),
  check (end_time is null or start_time is null or end_time > start_time)
);

create table public.action_schedule_changes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  action_item_id uuid not null references public.action_items(id) on delete cascade,
  previous_date date,
  previous_time time,
  new_date date,
  new_time time,
  reason text,
  created_at timestamptz not null default now()
);

create index action_items_user_schedule_idx
  on public.action_items(user_id, scheduled_date, scheduled_time);
create index action_items_user_due_idx
  on public.action_items(user_id, due_date);
create index calendar_events_user_date_idx
  on public.calendar_events(user_id, event_date, start_time);
create index action_schedule_changes_user_action_idx
  on public.action_schedule_changes(user_id, action_item_id, created_at desc);

create trigger calendar_events_updated_at
  before update on public.calendar_events
  for each row execute function public.set_updated_at();

alter table public.calendar_events enable row level security;
alter table public.action_schedule_changes enable row level security;

create policy "calendar events select own" on public.calendar_events for select using (user_id = auth.uid());
create policy "calendar events insert own" on public.calendar_events for insert with check (user_id = auth.uid());
create policy "calendar events update own" on public.calendar_events for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "calendar events delete own" on public.calendar_events for delete using (user_id = auth.uid());

create policy "schedule changes select own" on public.action_schedule_changes for select using (user_id = auth.uid());
create policy "schedule changes insert own" on public.action_schedule_changes for insert with check (user_id = auth.uid());

create or replace function public.reschedule_action(
  action_id uuid,
  target_date date,
  target_time time default null,
  change_reason text default null
)
returns void
language plpgsql
security invoker
as $$
declare
  owner_id uuid := auth.uid();
  action_row public.action_items;
  old_plan_id uuid;
  old_plan_action public.daily_plan_actions;
  new_plan_id uuid;
begin
  select * into action_row
    from public.action_items
    where id = action_id and user_id = owner_id
    for update;

  if action_row.id is null then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if action_row.status in ('DONE', 'SKIPPED', 'CANCELED') then
    raise exception 'ACTION_NOT_SCHEDULABLE';
  end if;

  if action_row.scheduled_date is not null then
    select id into old_plan_id
      from public.daily_plans
      where user_id = owner_id and plan_date = action_row.scheduled_date;

    if old_plan_id is not null then
      select * into old_plan_action
        from public.daily_plan_actions
        where user_id = owner_id
          and daily_plan_id = old_plan_id
          and action_item_id = action_id;
    end if;
  end if;

  update public.action_items
    set scheduled_date = target_date,
        scheduled_time = target_time,
        status = case when target_date is null then 'TODO'::public.action_status else 'PLANNED'::public.action_status end
    where id = action_id and user_id = owner_id;

  insert into public.action_schedule_changes(
    user_id, action_item_id, previous_date, previous_time, new_date, new_time, reason
  ) values (
    owner_id, action_id, action_row.scheduled_date, action_row.scheduled_time, target_date, target_time,
    nullif(trim(change_reason), '')
  );

  if old_plan_action.id is not null and target_date is distinct from action_row.scheduled_date then
    delete from public.daily_plan_actions where id = old_plan_action.id and user_id = owner_id;

    if target_date is not null then
      insert into public.daily_plans(user_id, plan_date)
      values (owner_id, target_date)
      on conflict (user_id, plan_date) do update set updated_at = now()
      returning id into new_plan_id;

      insert into public.daily_plan_actions(
        user_id, daily_plan_id, action_item_id, is_core, sort_order, result_status, reflection
      ) values (
        owner_id, new_plan_id, action_id, old_plan_action.is_core,
        old_plan_action.sort_order, 'NOT_STARTED', old_plan_action.reflection
      )
      on conflict (daily_plan_id, action_item_id) do update
        set is_core = excluded.is_core,
            sort_order = excluded.sort_order,
            result_status = 'NOT_STARTED';
    end if;
  end if;
end;
$$;

create or replace function public.add_core_action_to_today(action_id uuid, target_date date, make_core boolean)
returns uuid
language plpgsql
security invoker
as $$
declare
  owner_id uuid := auth.uid();
  plan_id uuid;
  max_core integer;
  current_core integer;
  row_id uuid;
  previous_date date;
  previous_time time;
begin
  select scheduled_date, scheduled_time into previous_date, previous_time
    from public.action_items
    where id = action_id and user_id = owner_id and status <> 'DONE'
    for update;
  if not found then raise exception 'RESOURCE_NOT_FOUND'; end if;

  insert into public.daily_plans(user_id, plan_date)
  values (owner_id, target_date)
  on conflict (user_id, plan_date) do update set updated_at = now()
  returning id into plan_id;

  if make_core then
    select max_core_actions into max_core from public.profiles where id = owner_id;
    select count(*) into current_core from public.daily_plan_actions where daily_plan_id = plan_id and user_id = owner_id and is_core;
    if current_core >= coalesce(max_core, 3) then raise exception 'CORE_ACTION_LIMIT_EXCEEDED'; end if;
  end if;

  insert into public.daily_plan_actions(user_id, daily_plan_id, action_item_id, is_core)
  values (owner_id, plan_id, action_id, make_core)
  on conflict (daily_plan_id, action_item_id) do update set is_core = excluded.is_core
  returning id into row_id;

  update public.action_items set status = 'PLANNED', scheduled_date = target_date where id = action_id and user_id = owner_id;

  if previous_date is distinct from target_date then
    insert into public.action_schedule_changes(user_id, action_item_id, previous_date, previous_time, new_date, new_time, reason)
    values (owner_id, action_id, previous_date, previous_time, target_date, previous_time, 'Today에 추가');
  end if;
  return row_id;
end;
$$;
