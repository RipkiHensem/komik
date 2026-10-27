-- Run once in the Supabase SQL Editor for the ComicStream project.
-- Public reads; only allowlisted admins may create or change comic captions.

create table if not exists public.comic_synopsis_overrides (
  comic_id text primary key,
  synopsis text not null check (
    length(btrim(synopsis)) between 1 and 5000
  ),
  updated_at timestamptz not null default now()
);

alter table public.comic_synopsis_overrides enable row level security;

revoke all on table public.comic_synopsis_overrides from public, anon, authenticated;
grant select on table public.comic_synopsis_overrides to anon, authenticated;
grant insert, update on table public.comic_synopsis_overrides to authenticated;

drop policy if exists "Anyone can read comic captions"
  on public.comic_synopsis_overrides;
create policy "Anyone can read comic captions"
  on public.comic_synopsis_overrides for select
  to anon, authenticated
  using (true);

drop policy if exists "Admins can insert comic captions"
  on public.comic_synopsis_overrides;
create policy "Admins can insert comic captions"
  on public.comic_synopsis_overrides for insert
  to authenticated
  with check (
    exists (
      select 1 from public.admin_users
      where email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  );

drop policy if exists "Admins can update comic captions"
  on public.comic_synopsis_overrides;
create policy "Admins can update comic captions"
  on public.comic_synopsis_overrides for update
  to authenticated
  using (
    exists (
      select 1 from public.admin_users
      where email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  )
  with check (
    exists (
      select 1 from public.admin_users
      where email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  );
