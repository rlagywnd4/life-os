create extension if not exists "pgcrypto";

create type inbox_category as enum ('SERVICE_IDEA','STUDY','CAREER','EXERCISE','CONTENT','HOBBY','LIFE','TRAVEL','PURCHASE','ETC');
create type inbox_status as enum ('UNREVIEWED','CONVERTED_TO_PROJECT','SOMEDAY','DISCARDED','ARCHIVED');
create type project_status as enum ('ACTIVE','WAITING','PAUSED','COMPLETED','ABANDONED','ARCHIVED');
create type action_status as enum ('TODO','PLANNED','IN_PROGRESS','DONE','SKIPPED','CANCELED');
create type energy_level as enum ('LOW','MEDIUM','HIGH');
create type day_mode as enum ('NORMAL','REST','RECOVERY','TRAVEL','BUSY');
create type plan_result_status as enum ('NOT_STARTED','DONE','PARTIAL','MOVED','SKIPPED');
create type weekly_review_status as enum ('IN_PROGRESS','COMPLETED');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  timezone text not null default 'Asia/Seoul',
  week_start_day smallint not null default 1 check (week_start_day between 0 and 6),
  max_active_projects integer not null default 3 check (max_active_projects between 1 and 12),
  max_core_actions integer not null default 3 check (max_core_actions between 1 and 12),
  recommended_action_minutes integer not null default 30 check (recommended_action_minutes > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.inbox_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  category inbox_category not null default 'ETC',
  status inbox_status not null default 'UNREVIEWED',
  reviewed_at timestamptz,
  converted_project_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  source_inbox_item_id uuid references public.inbox_items(id) on delete set null,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  reason text,
  desired_outcome text,
  status project_status not null default 'WAITING',
  priority integer not null default 0,
  started_at timestamptz,
  target_date date,
  completed_at timestamptz,
  abandoned_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.inbox_items
  add constraint inbox_converted_project_fk foreign key (converted_project_id) references public.projects(id) on delete set null;

create table public.action_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  estimated_minutes integer not null default 30 check (estimated_minutes > 0),
  status action_status not null default 'TODO',
  priority integer not null default 0,
  scheduled_date date,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.daily_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  plan_date date not null,
  energy_level energy_level not null default 'MEDIUM',
  day_mode day_mode not null default 'NORMAL',
  note text,
  rest_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, plan_date)
);

create table public.daily_plan_actions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  daily_plan_id uuid not null references public.daily_plans(id) on delete cascade,
  action_item_id uuid not null references public.action_items(id) on delete cascade,
  is_core boolean not null default false,
  sort_order integer not null default 0,
  result_status plan_result_status not null default 'NOT_STARTED',
  reflection text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(daily_plan_id, action_item_id)
);

create table public.someday_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  source_inbox_item_id uuid references public.inbox_items(id) on delete set null,
  title text not null,
  description text,
  category inbox_category not null default 'ETC',
  last_reviewed_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.weekly_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  week_start_date date not null,
  week_end_date date not null check (week_end_date >= week_start_date),
  status weekly_review_status not null default 'IN_PROGRESS',
  current_step integer not null default 1 check (current_step between 1 and 5),
  went_well text,
  was_difficult text,
  felt_closer_to_desired_life text,
  do_less_next_week text,
  next_week_direction text,
  energy_summary text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  unique(user_id, week_start_date)
);

create table public.weekly_review_focus_projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  weekly_review_id uuid not null references public.weekly_reviews(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique(weekly_review_id, project_id),
  check (sort_order between 0 and 2)
);

create table public.daily_check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  check_in_date date not null,
  energy_level energy_level not null,
  mood text,
  body_condition text,
  mental_load text,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, check_in_date)
);

create index inbox_items_user_status_idx on public.inbox_items(user_id, status, created_at desc);
create index projects_user_status_idx on public.projects(user_id, status, updated_at desc);
create index action_items_user_project_status_idx on public.action_items(user_id, project_id, status);
create index daily_plans_user_date_idx on public.daily_plans(user_id, plan_date desc);
create index weekly_reviews_user_week_idx on public.weekly_reviews(user_id, week_start_date desc);

create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger inbox_updated_at before update on public.inbox_items for each row execute function public.set_updated_at();
create trigger projects_updated_at before update on public.projects for each row execute function public.set_updated_at();
create trigger actions_updated_at before update on public.action_items for each row execute function public.set_updated_at();
create trigger daily_plans_updated_at before update on public.daily_plans for each row execute function public.set_updated_at();
create trigger daily_plan_actions_updated_at before update on public.daily_plan_actions for each row execute function public.set_updated_at();
create trigger someday_updated_at before update on public.someday_items for each row execute function public.set_updated_at();
create trigger weekly_reviews_updated_at before update on public.weekly_reviews for each row execute function public.set_updated_at();
create trigger daily_check_ins_updated_at before update on public.daily_check_ins for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.prevent_action_on_closed_project()
returns trigger
language plpgsql
as $$
declare
  project_owner uuid;
  project_state project_status;
begin
  select user_id, status into project_owner, project_state from public.projects where id = new.project_id;
  if project_owner is null or project_owner <> auth.uid() then
    raise exception 'PROJECT_NOT_EDITABLE';
  end if;
  if project_state in ('COMPLETED', 'ABANDONED', 'ARCHIVED') then
    raise exception 'PROJECT_NOT_EDITABLE';
  end if;
  new.user_id = auth.uid();
  return new;
end;
$$;

create trigger action_project_guard before insert on public.action_items for each row execute function public.prevent_action_on_closed_project();

create or replace function public.convert_inbox_to_project(
  inbox_id uuid,
  project_title text,
  project_reason text,
  project_desired_outcome text,
  activate_now boolean
)
returns uuid
language plpgsql
security invoker
as $$
declare
  owner_id uuid := auth.uid();
  item public.inbox_items;
  profile_limit integer;
  active_count integer;
  new_project_id uuid;
  next_status project_status := case when activate_now then 'ACTIVE'::project_status else 'WAITING'::project_status end;
begin
  select * into item from public.inbox_items where id = inbox_id and user_id = owner_id for update;
  if item.id is null then raise exception 'RESOURCE_NOT_FOUND'; end if;
  if item.status <> 'UNREVIEWED' then raise exception 'INBOX_ALREADY_CONVERTED'; end if;

  if activate_now then
    select max_active_projects into profile_limit from public.profiles where id = owner_id;
    select count(*) into active_count from public.projects where user_id = owner_id and status = 'ACTIVE';
    if active_count >= coalesce(profile_limit, 3) then
      raise exception 'ACTIVE_PROJECT_LIMIT_EXCEEDED';
    end if;
  end if;

  insert into public.projects(user_id, source_inbox_item_id, title, reason, desired_outcome, status, started_at)
  values (owner_id, item.id, project_title, project_reason, project_desired_outcome, next_status, case when activate_now then now() else null end)
  returning id into new_project_id;

  update public.inbox_items
    set status = 'CONVERTED_TO_PROJECT', reviewed_at = now(), converted_project_id = new_project_id
    where id = item.id and user_id = owner_id;

  return new_project_id;
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
begin
  if not exists (select 1 from public.action_items where id = action_id and user_id = owner_id and status <> 'DONE') then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  insert into public.daily_plans(user_id, plan_date)
  values (owner_id, target_date)
  on conflict (user_id, plan_date) do update set updated_at = now()
  returning id into plan_id;

  if make_core then
    select max_core_actions into max_core from public.profiles where id = owner_id;
    select count(*) into current_core from public.daily_plan_actions where daily_plan_id = plan_id and user_id = owner_id and is_core;
    if current_core >= coalesce(max_core, 3) then
      raise exception 'CORE_ACTION_LIMIT_EXCEEDED';
    end if;
  end if;

  insert into public.daily_plan_actions(user_id, daily_plan_id, action_item_id, is_core)
  values (owner_id, plan_id, action_id, make_core)
  on conflict (daily_plan_id, action_item_id) do update set is_core = excluded.is_core
  returning id into row_id;

  update public.action_items set status = 'PLANNED', scheduled_date = target_date where id = action_id and user_id = owner_id;
  return row_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.inbox_items enable row level security;
alter table public.projects enable row level security;
alter table public.action_items enable row level security;
alter table public.daily_plans enable row level security;
alter table public.daily_plan_actions enable row level security;
alter table public.someday_items enable row level security;
alter table public.weekly_reviews enable row level security;
alter table public.weekly_review_focus_projects enable row level security;
alter table public.daily_check_ins enable row level security;

create policy "profiles select own" on public.profiles for select using (id = auth.uid());
create policy "profiles update own" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

create policy "inbox select own" on public.inbox_items for select using (user_id = auth.uid());
create policy "inbox insert own" on public.inbox_items for insert with check (user_id = auth.uid());
create policy "inbox update own" on public.inbox_items for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "inbox delete own" on public.inbox_items for delete using (user_id = auth.uid());

create policy "projects select own" on public.projects for select using (user_id = auth.uid());
create policy "projects insert own" on public.projects for insert with check (user_id = auth.uid());
create policy "projects update own" on public.projects for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "projects delete own" on public.projects for delete using (user_id = auth.uid());

create policy "actions select own" on public.action_items for select using (user_id = auth.uid());
create policy "actions insert own" on public.action_items for insert with check (user_id = auth.uid());
create policy "actions update own" on public.action_items for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "actions delete own" on public.action_items for delete using (user_id = auth.uid());

create policy "daily plans select own" on public.daily_plans for select using (user_id = auth.uid());
create policy "daily plans insert own" on public.daily_plans for insert with check (user_id = auth.uid());
create policy "daily plans update own" on public.daily_plans for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "daily plans delete own" on public.daily_plans for delete using (user_id = auth.uid());

create policy "daily plan actions select own" on public.daily_plan_actions for select using (user_id = auth.uid());
create policy "daily plan actions insert own" on public.daily_plan_actions for insert with check (user_id = auth.uid());
create policy "daily plan actions update own" on public.daily_plan_actions for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "daily plan actions delete own" on public.daily_plan_actions for delete using (user_id = auth.uid());

create policy "someday select own" on public.someday_items for select using (user_id = auth.uid());
create policy "someday insert own" on public.someday_items for insert with check (user_id = auth.uid());
create policy "someday update own" on public.someday_items for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "someday delete own" on public.someday_items for delete using (user_id = auth.uid());

create policy "weekly reviews select own" on public.weekly_reviews for select using (user_id = auth.uid());
create policy "weekly reviews insert own" on public.weekly_reviews for insert with check (user_id = auth.uid());
create policy "weekly reviews update own" on public.weekly_reviews for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "weekly reviews delete own" on public.weekly_reviews for delete using (user_id = auth.uid());

create policy "focus projects select own" on public.weekly_review_focus_projects for select using (user_id = auth.uid());
create policy "focus projects insert own" on public.weekly_review_focus_projects for insert with check (user_id = auth.uid());
create policy "focus projects update own" on public.weekly_review_focus_projects for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "focus projects delete own" on public.weekly_review_focus_projects for delete using (user_id = auth.uid());

create policy "check ins select own" on public.daily_check_ins for select using (user_id = auth.uid());
create policy "check ins insert own" on public.daily_check_ins for insert with check (user_id = auth.uid());
create policy "check ins update own" on public.daily_check_ins for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "check ins delete own" on public.daily_check_ins for delete using (user_id = auth.uid());
