create type health_activity_level as enum ('LOW','LIGHT','MODERATE','HIGH');
create type health_weigh_in_time as enum ('MORNING','AFTER_WORK','EVENING','BEFORE_SLEEP','OTHER');
create type health_condition_level as enum ('VERY_LOW','LOW','NORMAL','GOOD','VERY_GOOD');
create type health_stress_level as enum ('LOW','NORMAL','HIGH');
create type health_exercise_completion as enum ('NOT_DONE','FULL','MINIMUM','ALTERNATIVE','REST');
create type health_completion_status as enum ('DONE','PARTIAL','ALTERNATIVE','REST','UNRECORDED');

create table public.health_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  height_cm numeric(5,2),
  birth_year integer check (birth_year between 1900 and extract(year from now())::integer),
  current_weight_kg numeric(5,2) not null check (current_weight_kg > 0),
  target_weight_kg numeric(5,2) not null check (target_weight_kg > 0),
  goal_description text,
  activity_level health_activity_level,
  usual_weigh_in_time health_weigh_in_time,
  weekly_loss_rate_kg numeric(4,2) not null default 0.5 check (weekly_loss_rate_kg > 0 and weekly_loss_rate_kg <= 2),
  weekday_brisk_walk_minutes integer not null default 20 check (weekday_brisk_walk_minutes > 0),
  low_energy_walk_minutes integer not null default 5 check (low_energy_walk_minutes > 0),
  snack_reminder_enabled boolean not null default true,
  snack_reminder_time time not null default '17:30',
  snack_weekdays smallint[] not null default array[1,2,3,4,5]::smallint[],
  default_snack_name text not null default '퇴근 전 계획된 간식',
  default_snack_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table public.health_weight_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  target_weight_kg numeric(5,2) not null check (target_weight_kg > 0),
  goal_name text not null,
  sort_order integer not null default 0,
  achieved boolean not null default false,
  achieved_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.health_check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  check_in_date date not null,
  weight_kg numeric(5,2) check (weight_kg > 0),
  steps integer check (steps >= 0),
  brisk_walk_status health_completion_status not null default 'UNRECORDED',
  planned_snack_done boolean,
  unplanned_snack boolean,
  dinner_overeating boolean,
  free_meal boolean,
  alcohol boolean,
  exercise_completion health_exercise_completion not null default 'NOT_DONE',
  sleep_hours numeric(4,2) check (sleep_hours >= 0 and sleep_hours <= 24),
  condition_level health_condition_level,
  stress_level health_stress_level,
  low_energy_mode boolean not null default false,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, check_in_date)
);

create index health_profiles_user_idx on public.health_profiles(user_id);
create index health_goals_user_order_idx on public.health_weight_goals(user_id, sort_order);
create index health_check_ins_user_date_idx on public.health_check_ins(user_id, check_in_date desc);

create trigger health_profiles_updated_at before update on public.health_profiles for each row execute function public.set_updated_at();
create trigger health_goals_updated_at before update on public.health_weight_goals for each row execute function public.set_updated_at();
create trigger health_check_ins_updated_at before update on public.health_check_ins for each row execute function public.set_updated_at();

create or replace function public.create_default_health_goals()
returns trigger
language plpgsql
security invoker
as $$
declare
  first_target numeric(5,2);
  second_target numeric(5,2);
begin
  first_target := greatest(new.target_weight_kg, new.current_weight_kg - 5);
  second_target := greatest(new.target_weight_kg, new.current_weight_kg - 10);

  if first_target > new.target_weight_kg and first_target < new.current_weight_kg then
    insert into public.health_weight_goals(user_id, target_weight_kg, goal_name, sort_order)
    values (new.user_id, first_target, '1단계: 5kg 감량', 1);
  end if;

  if second_target > new.target_weight_kg and second_target < new.current_weight_kg and second_target <> first_target then
    insert into public.health_weight_goals(user_id, target_weight_kg, goal_name, sort_order)
    values (new.user_id, second_target, '2단계: 10kg 감량', 2);
  end if;

  insert into public.health_weight_goals(user_id, target_weight_kg, goal_name, sort_order)
  values (new.user_id, new.target_weight_kg, '최종 목표 체중', 3);

  return new;
end;
$$;

create trigger health_profile_default_goals
  after insert on public.health_profiles
  for each row execute function public.create_default_health_goals();

alter table public.health_profiles enable row level security;
alter table public.health_weight_goals enable row level security;
alter table public.health_check_ins enable row level security;

create policy "health profiles select own" on public.health_profiles for select using (user_id = auth.uid());
create policy "health profiles insert own" on public.health_profiles for insert with check (user_id = auth.uid());
create policy "health profiles update own" on public.health_profiles for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "health profiles delete own" on public.health_profiles for delete using (user_id = auth.uid());

create policy "health goals select own" on public.health_weight_goals for select using (user_id = auth.uid());
create policy "health goals insert own" on public.health_weight_goals for insert with check (user_id = auth.uid());
create policy "health goals update own" on public.health_weight_goals for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "health goals delete own" on public.health_weight_goals for delete using (user_id = auth.uid());

create policy "health check ins select own" on public.health_check_ins for select using (user_id = auth.uid());
create policy "health check ins insert own" on public.health_check_ins for insert with check (user_id = auth.uid());
create policy "health check ins update own" on public.health_check_ins for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "health check ins delete own" on public.health_check_ins for delete using (user_id = auth.uid());
