-- Yomu: rolling seven-day unique readers, plus explicit admin pin/exclude.
-- Reader identifiers never leave the private schema. Existing histories are unchanged.
begin;
create schema if not exists yomu_private;
revoke all on schema yomu_private from public;
grant usage on schema yomu_private to anon, authenticated;
create table if not exists yomu_private.comic_readers (
  comic_id text not null check (length(comic_id) between 1 and 250),
  reader_key text not null,
  format text not null check (format in ('Manhwa','Manga','Manhua')),
  last_read_at timestamptz not null default now(),
  primary key (comic_id, reader_key)
);
alter table yomu_private.comic_readers enable row level security;
revoke all on yomu_private.comic_readers from public, anon, authenticated;
create index if not exists comic_readers_recent_idx
  on yomu_private.comic_readers (last_read_at desc, comic_id);
alter table public.comics add column if not exists popular_override boolean;
comment on column public.comics.popular_override is 'NULL=automatic, true=admin pinned, false=excluded from popular';

create or replace function yomu_private.record_comic_read(p_comic_id text, p_format text, p_guest_id uuid default null)
returns void language plpgsql security definer set search_path = '' as $$
declare v_reader text;
begin
  if p_comic_id is null or length(p_comic_id) not between 1 and 250
     or p_format is null or p_format not in ('Manhwa','Manga','Manhua') then
    raise exception 'Invalid comic' using errcode='22023';
  end if;
  if auth.uid() is not null then
    v_reader := 'user:' || auth.uid()::text;
  elsif p_guest_id is not null then
    v_reader := 'guest:' || pg_catalog.md5(p_guest_id::text);
  else
    raise exception 'Reader identity required' using errcode='22023';
  end if;
  if exists(select 1 from public.hidden_comics where comic_id=p_comic_id) then return; end if;
  insert into yomu_private.comic_readers(comic_id, reader_key, format, last_read_at)
    values(p_comic_id, v_reader, p_format, now())
    on conflict(comic_id, reader_key) do update
      set last_read_at=excluded.last_read_at, format=excluded.format;
  -- A guest who signs in on this installation should not count twice for this comic.
  if auth.uid() is not null and p_guest_id is not null then
    delete from yomu_private.comic_readers where comic_id=p_comic_id
      and reader_key='guest:' || pg_catalog.md5(p_guest_id::text);
  end if;
end $$;
create or replace function public.record_comic_read(p_comic_id text, p_format text, p_guest_id uuid default null)
returns void language sql security invoker set search_path = '' as $$
  select yomu_private.record_comic_read(p_comic_id,p_format,p_guest_id);
$$;
create or replace function yomu_private.weekly_popular_comics(p_format text default null)
returns table(comic_id text, weekly_readers bigint)
language sql stable security definer set search_path = '' as $$
  select r.comic_id, count(*) as weekly_readers
  from yomu_private.comic_readers r
  where r.last_read_at > now() - interval '7 days'
    and (p_format is null or r.format=p_format)
    and not exists(select 1 from public.hidden_comics h where h.comic_id=r.comic_id)
  group by r.comic_id
  order by count(*) desc, max(r.last_read_at) desc, r.comic_id
  limit 100;
$$;
create or replace function public.weekly_popular_comics(p_format text default null)
returns table(comic_id text, weekly_readers bigint)
language sql stable security invoker set search_path = '' as $$
  select * from yomu_private.weekly_popular_comics(p_format);
$$;
revoke all on function yomu_private.record_comic_read(text,text,uuid), public.record_comic_read(text,text,uuid),
  yomu_private.weekly_popular_comics(text), public.weekly_popular_comics(text) from public;
grant execute on function yomu_private.record_comic_read(text,text,uuid), public.record_comic_read(text,text,uuid),
  yomu_private.weekly_popular_comics(text), public.weekly_popular_comics(text) to anon, authenticated;
notify pgrst, 'reload schema';
commit;
