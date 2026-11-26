-- Per-comic user rating, bookmark totals, and reader totals for Yomu.
-- Run after the Supabase project is active and the P11 weekly-reader setup exists.
begin;

create schema if not exists yomu_private;
revoke all on schema yomu_private from public;
grant usage on schema yomu_private to anon, authenticated;

create table if not exists yomu_private.comic_ratings (
  comic_id text not null check (length(comic_id) between 1 and 250),
  user_id uuid not null references auth.users(id) on delete cascade,
  rating smallint not null check (rating between 1 and 10),
  updated_at timestamptz not null default now(),
  primary key (comic_id, user_id)
);
alter table yomu_private.comic_ratings enable row level security;
revoke all on yomu_private.comic_ratings from public, anon, authenticated;
create index if not exists comic_ratings_comic_idx
  on yomu_private.comic_ratings (comic_id);
create index if not exists bookmarks_comic_id_idx
  on public.bookmarks (comic_id);

create or replace function yomu_private.get_comic_engagement(p_comic_id text)
returns table (
  reader_count bigint,
  bookmark_count bigint,
  rating_average numeric,
  rating_count bigint,
  user_rating smallint
)
language sql stable security definer set search_path = '' as $$
  select
    (select pg_catalog.count(*)::bigint
       from yomu_private.comic_readers r
      where r.comic_id = p_comic_id),
    (select pg_catalog.count(*)::bigint
       from public.bookmarks b
      where b.comic_id = p_comic_id),
    coalesce((select pg_catalog.round(pg_catalog.avg(r.rating)::numeric, 1)
       from yomu_private.comic_ratings r
      where r.comic_id = p_comic_id), 0::numeric),
    (select pg_catalog.count(*)::bigint
       from yomu_private.comic_ratings r
      where r.comic_id = p_comic_id),
    (select r.rating
       from yomu_private.comic_ratings r
      where r.comic_id = p_comic_id
        and r.user_id = auth.uid())
$$;

create or replace function public.get_comic_engagement(p_comic_id text)
returns table (
  reader_count bigint,
  bookmark_count bigint,
  rating_average numeric,
  rating_count bigint,
  user_rating smallint
)
language sql stable security invoker set search_path = '' as $$
  select * from yomu_private.get_comic_engagement(p_comic_id)
$$;

create or replace function yomu_private.rate_comic(
  p_comic_id text,
  p_rating smallint
)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;
  if p_comic_id is null or length(p_comic_id) not between 1 and 250 then
    raise exception 'Invalid comic id' using errcode = '22023';
  end if;
  if p_rating is null or p_rating not between 1 and 10 then
    raise exception 'Rating must be from 1 to 10' using errcode = '22023';
  end if;

  insert into yomu_private.comic_ratings(comic_id, user_id, rating)
  values (p_comic_id, auth.uid(), p_rating)
  on conflict (comic_id, user_id) do update
    set rating = excluded.rating, updated_at = pg_catalog.now();
end;
$$;

create or replace function public.rate_comic(p_comic_id text, p_rating smallint)
returns void
language sql security invoker set search_path = '' as $$
  select yomu_private.rate_comic(p_comic_id, p_rating)
$$;

revoke all on function yomu_private.get_comic_engagement(text),
  public.get_comic_engagement(text),
  yomu_private.rate_comic(text, smallint),
  public.rate_comic(text, smallint) from public;
revoke all on function yomu_private.rate_comic(text, smallint) from anon;
grant execute on function yomu_private.get_comic_engagement(text),
  public.get_comic_engagement(text) to anon, authenticated;
grant execute on function yomu_private.rate_comic(text, smallint),
  public.rate_comic(text, smallint) to authenticated;

notify pgrst, 'reload schema';
commit;
