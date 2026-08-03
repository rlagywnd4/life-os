-- Inbox triage and project planning foundation. Existing rows remain valid:
-- reason / desired_outcome are copied into the clearer project-planning fields.

alter table public.projects
  add column if not exists goal text,
  add column if not exists completion_criteria text,
  add column if not exists next_action_id uuid,
  add column if not exists archived_at timestamptz;

update public.projects
set goal = coalesce(goal, reason),
    completion_criteria = coalesce(completion_criteria, desired_outcome)
where goal is null or completion_criteria is null;

alter table public.action_items
  add column if not exists sort_order integer not null default 0,
  add column if not exists is_stage boolean not null default false,
  add column if not exists started_date date,
  add column if not exists due_date date,
  add column if not exists scheduled_time time,
  add column if not exists scheduled_end_time time,
  add column if not exists is_all_day boolean not null default true,
  add column if not exists actual_minutes integer check (actual_minutes is null or actual_minutes >= 0),
  add column if not exists deleted_at timestamptz;

alter table public.action_items
  add constraint action_schedule_time_order
  check (scheduled_end_time is null or scheduled_time is null or scheduled_end_time > scheduled_time) not valid;

alter table public.action_items validate constraint action_schedule_time_order;

create table if not exists public.project_milestones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  action_item_id uuid references public.action_items(id) on delete set null,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  target_date date,
  completed_at timestamptz,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.project_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  action_item_id uuid references public.action_items(id) on delete set null,
  milestone_id uuid references public.project_milestones(id) on delete set null,
  record_type text not null check (record_type in ('NOTE', 'ACTION_COMPLETED', 'PROJECT_STATUS_CHANGED', 'TARGET_DATE_CHANGED', 'PLAN_CHANGED', 'MILESTONE_COMPLETED')),
  content text not null check (char_length(trim(content)) > 0),
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  source_inbox_item_id uuid references public.inbox_items(id) on delete set null,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  event_date date not null,
  start_time time,
  end_time time,
  is_all_day boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time is null or start_time is null or end_time > start_time)
);

create index if not exists action_items_project_parent_order_idx
  on public.action_items(user_id, project_id, parent_action_id, sort_order, created_at)
  where deleted_at is null;
create index if not exists action_items_project_schedule_idx
  on public.action_items(user_id, project_id, scheduled_date, scheduled_time)
  where deleted_at is null;
create index if not exists milestones_project_target_idx
  on public.project_milestones(user_id, project_id, target_date, sort_order);
create index if not exists project_records_project_created_idx
  on public.project_records(user_id, project_id, created_at desc);
create index if not exists calendar_events_user_date_idx
  on public.calendar_events(user_id, event_date, start_time);

create trigger project_milestones_updated_at
  before update on public.project_milestones
  for each row execute function public.set_updated_at();
create trigger project_records_updated_at
  before update on public.project_records
  for each row execute function public.set_updated_at();
create trigger calendar_events_updated_at
  before update on public.calendar_events
  for each row execute function public.set_updated_at();

alter table public.project_milestones enable row level security;
alter table public.project_records enable row level security;
alter table public.calendar_events enable row level security;
create policy "project milestones select own" on public.project_milestones for select using (user_id = auth.uid());
create policy "project milestones insert own" on public.project_milestones for insert with check (user_id = auth.uid());
create policy "project milestones update own" on public.project_milestones for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "project milestones delete own" on public.project_milestones for delete using (user_id = auth.uid());
create policy "project records select own" on public.project_records for select using (user_id = auth.uid());
create policy "project records insert own" on public.project_records for insert with check (user_id = auth.uid());
create policy "project records update own" on public.project_records for update using (user_id = auth.uid()) with check (user_id = auth.uid() and is_system = false);
create policy "project records delete own" on public.project_records for delete using (user_id = auth.uid() and is_system = false);
create policy "calendar events select own" on public.calendar_events for select using (user_id = auth.uid());
create policy "calendar events insert own" on public.calendar_events for insert with check (user_id = auth.uid());
create policy "calendar events update own" on public.calendar_events for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "calendar events delete own" on public.calendar_events for delete using (user_id = auth.uid());

create or replace function public.validate_project_next_action()
returns trigger language plpgsql as $$
declare
  action_project_id uuid;
  action_owner_id uuid;
begin
  if new.next_action_id is null then return new; end if;
  select project_id, user_id into action_project_id, action_owner_id
  from public.action_items where id = new.next_action_id and deleted_at is null;
  if action_project_id is null or action_project_id <> new.id or action_owner_id <> new.user_id then
    raise exception 'PROJECT_NEXT_ACTION_NOT_AVAILABLE';
  end if;
  return new;
end;
$$;

create trigger project_next_action_guard
  before insert or update of next_action_id, user_id on public.projects
  for each row execute function public.validate_project_next_action();

create or replace function public.validate_milestone_action()
returns trigger language plpgsql as $$
declare
  action_project_id uuid;
  action_owner_id uuid;
begin
  if new.action_item_id is null then return new; end if;
  select project_id, user_id into action_project_id, action_owner_id
  from public.action_items where id = new.action_item_id and deleted_at is null;
  if action_project_id is null or action_project_id <> new.project_id or action_owner_id <> new.user_id then
    raise exception 'MILESTONE_ACTION_NOT_AVAILABLE';
  end if;
  return new;
end;
$$;

create trigger milestone_action_guard
  before insert or update of action_item_id, project_id, user_id on public.project_milestones
  for each row execute function public.validate_milestone_action();

create or replace function public.create_project_plan(
  p_title text,
  p_description text default null,
  p_goal text default null,
  p_completion_criteria text default null,
  p_started_date date default null,
  p_target_date date default null,
  p_status public.project_status default 'DRAFT',
  p_stage_titles jsonb default '[]'::jsonb,
  p_first_action_title text default null,
  p_source_inbox_id uuid default null
)
returns uuid language plpgsql security invoker as $$
declare
  owner_id uuid := auth.uid();
  new_project_id uuid;
  stage_id uuid;
  first_action_id uuid;
  stage_title text;
  source_item public.inbox_items;
  position integer := 0;
begin
  if nullif(trim(p_title), '') is null then raise exception 'PROJECT_TITLE_REQUIRED'; end if;
  if p_target_date is not null and p_started_date is not null and p_target_date < p_started_date then
    raise exception 'PROJECT_DATE_RANGE_INVALID';
  end if;

  if p_source_inbox_id is not null then
    select * into source_item from public.inbox_items
      where id = p_source_inbox_id and user_id = owner_id for update;
    if source_item.id is null then raise exception 'RESOURCE_NOT_FOUND'; end if;
    if source_item.status = 'CONVERTED_TO_PROJECT' then
      return source_item.converted_project_id;
    end if;
    if source_item.status <> 'UNREVIEWED' then raise exception 'INBOX_ALREADY_PROCESSED'; end if;
  end if;

  insert into public.projects(
    user_id, source_inbox_item_id, title, description, reason, desired_outcome,
    goal, completion_criteria, status, started_at, target_date
  ) values (
    owner_id, p_source_inbox_id, trim(p_title), nullif(trim(p_description), ''),
    nullif(trim(p_goal), ''), nullif(trim(p_completion_criteria), ''),
    nullif(trim(p_goal), ''), nullif(trim(p_completion_criteria), ''), p_status,
    p_started_date::timestamptz, p_target_date
  ) returning id into new_project_id;

  for stage_title in select value #>> '{}' from jsonb_array_elements(coalesce(p_stage_titles, '[]'::jsonb)) loop
    if nullif(trim(stage_title), '') is not null then
      insert into public.action_items(user_id, project_id, title, is_stage, sort_order)
      values (owner_id, new_project_id, trim(stage_title), true, position)
      returning id into stage_id;
      position := position + 1;
    end if;
  end loop;

  if nullif(trim(p_first_action_title), '') is not null then
    select id into stage_id from public.action_items
      where project_id = new_project_id and user_id = owner_id and is_stage and deleted_at is null
      order by sort_order, created_at limit 1;
    insert into public.action_items(user_id, project_id, parent_action_id, title, sort_order)
    values (owner_id, new_project_id, stage_id, trim(p_first_action_title), 0)
    returning id into first_action_id;
    update public.projects set next_action_id = first_action_id where id = new_project_id;
  end if;

  insert into public.project_records(user_id, project_id, record_type, content, is_system)
  values (owner_id, new_project_id, 'PLAN_CHANGED', '프로젝트 계획을 만들었습니다.', true);

  if p_source_inbox_id is not null then
    update public.inbox_items
      set status = 'CONVERTED_TO_PROJECT', reviewed_at = now(), converted_project_id = new_project_id
      where id = p_source_inbox_id and user_id = owner_id;
  end if;
  return new_project_id;
end;
$$;

create or replace function public.delete_action_item(p_action_id uuid, p_strategy text default 'REPARENT')
returns void language plpgsql security invoker as $$
declare
  owner_id uuid := auth.uid();
  item public.action_items;
begin
  select * into item from public.action_items where id = p_action_id and user_id = owner_id for update;
  if item.id is null then raise exception 'RESOURCE_NOT_FOUND'; end if;
  if p_strategy = 'CASCADE' then
    with recursive descendants as (
      select id from public.action_items where id = item.id
      union all
      select child.id from public.action_items child join descendants parent on child.parent_action_id = parent.id
    ) update public.action_items set deleted_at = now() where id in (select id from descendants) and user_id = owner_id;
  elsif p_strategy = 'REPARENT' then
    update public.action_items set parent_action_id = item.parent_action_id
      where parent_action_id = item.id and user_id = owner_id;
    update public.action_items set deleted_at = now() where id = item.id and user_id = owner_id;
  else
    raise exception 'ACTION_DELETE_STRATEGY_INVALID';
  end if;
  update public.projects set next_action_id = null
    where id = item.project_id and next_action_id = item.id;
end;
$$;
