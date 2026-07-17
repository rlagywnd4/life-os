alter table public.action_items
  add column parent_action_id uuid references public.action_items(id) on delete set null;

create index action_items_user_project_parent_idx
  on public.action_items(user_id, project_id, parent_action_id, created_at);

create or replace function public.validate_action_hierarchy()
returns trigger
language plpgsql
as $$
declare
  parent_owner_id uuid;
  parent_project_id uuid;
begin
  if new.parent_action_id is null then
    return new;
  end if;

  if new.parent_action_id = new.id then
    raise exception 'ACTION_HIERARCHY_CYCLE';
  end if;

  select user_id, project_id
    into parent_owner_id, parent_project_id
    from public.action_items
    where id = new.parent_action_id;

  if parent_owner_id is null then
    raise exception 'ACTION_PARENT_NOT_FOUND';
  end if;

  if parent_owner_id <> new.user_id or parent_project_id <> new.project_id then
    raise exception 'ACTION_PARENT_NOT_AVAILABLE';
  end if;

  if exists (
    with recursive ancestors as (
      select id, parent_action_id
        from public.action_items
        where id = new.parent_action_id
      union
      select action.id, action.parent_action_id
        from public.action_items action
        join ancestors ancestor on action.id = ancestor.parent_action_id
    )
    select 1 from ancestors where id = new.id
  ) then
    raise exception 'ACTION_HIERARCHY_CYCLE';
  end if;

  return new;
end;
$$;

create trigger action_hierarchy_guard
  before insert or update of parent_action_id, project_id, user_id
  on public.action_items
  for each row execute function public.validate_action_hierarchy();
