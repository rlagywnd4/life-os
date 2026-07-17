create type life_context_privacy_level as enum ('PUBLIC_PROFILE','PRIVATE','HIGHLY_SENSITIVE');

create table public.life_context_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  version text not null,
  title text not null,
  source_date date,
  purpose text,
  privacy_level life_context_privacy_level not null default 'PRIVATE',
  content_markdown text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, version)
);

create table public.life_context_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  document_id uuid not null references public.life_context_documents(id) on delete cascade,
  entry_key text not null,
  title text not null,
  category text not null,
  privacy_level life_context_privacy_level not null default 'PRIVATE',
  content_markdown text,
  data jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, document_id, entry_key)
);

create index life_context_documents_user_version_idx on public.life_context_documents(user_id, version);
create index life_context_entries_user_category_idx on public.life_context_entries(user_id, category, sort_order);
create index life_context_entries_document_idx on public.life_context_entries(document_id, sort_order);

create trigger life_context_documents_updated_at
  before update on public.life_context_documents
  for each row execute function public.set_updated_at();

create trigger life_context_entries_updated_at
  before update on public.life_context_entries
  for each row execute function public.set_updated_at();

alter table public.life_context_documents enable row level security;
alter table public.life_context_entries enable row level security;

create policy "life context documents select own" on public.life_context_documents for select using (user_id = auth.uid());
create policy "life context documents insert own" on public.life_context_documents for insert with check (user_id = auth.uid());
create policy "life context documents update own" on public.life_context_documents for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "life context documents delete own" on public.life_context_documents for delete using (user_id = auth.uid());

create policy "life context entries select own" on public.life_context_entries for select using (user_id = auth.uid());
create policy "life context entries insert own" on public.life_context_entries for insert with check (user_id = auth.uid());
create policy "life context entries update own" on public.life_context_entries for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "life context entries delete own" on public.life_context_entries for delete using (user_id = auth.uid());
