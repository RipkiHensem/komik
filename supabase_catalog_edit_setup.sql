-- Run after supabase_admin_crud.sql. No existing catalog rows are removed.
begin;
alter table public.comics add column if not exists content_updated_at timestamptz;
create table if not exists public.chapter_metadata_overrides (
  chapter_id text primary key,
  comic_id text not null,
  title text not null check (length(btrim(title)) between 1 and 250),
  chapter_number integer not null check (chapter_number >= 0),
  released_at timestamptz
);
create index if not exists chapter_metadata_comic_idx
  on public.chapter_metadata_overrides(comic_id);
alter table public.chapter_metadata_overrides enable row level security;
revoke all on public.chapter_metadata_overrides from public, anon, authenticated;
grant select on public.chapter_metadata_overrides to anon, authenticated;
grant insert, update on public.chapter_metadata_overrides to authenticated;
drop policy if exists "Read chapter metadata" on public.chapter_metadata_overrides;
create policy "Read chapter metadata" on public.chapter_metadata_overrides
  for select to anon, authenticated using (true);
drop policy if exists "Admin chapter metadata" on public.chapter_metadata_overrides;
create policy "Admin chapter metadata" on public.chapter_metadata_overrides
  for all to authenticated
  using (exists (select 1 from public.admin_users where email = lower((select auth.jwt()->>'email'))))
  with check (exists (select 1 from public.admin_users where email = lower((select auth.jwt()->>'email'))));

-- Profiles remain private. This public projection contains only the display
-- identity of people who have chosen to publish a collection, never emails.
create or replace function public.public_collection_authors()
returns table(id uuid, username text, avatar_url text)
language sql stable security definer set search_path = '' as $$
  select p.id, p.username, p.avatar_url from public.profiles p
  where exists (select 1 from public.collections c where c.user_id = p.id and c.is_public = true);
$$;
revoke all on function public.public_collection_authors() from public;
grant execute on function public.public_collection_authors() to anon, authenticated;
commit;
