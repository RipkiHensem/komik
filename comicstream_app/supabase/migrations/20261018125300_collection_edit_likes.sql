begin;

create table public.collection_likes (
  collection_id uuid not null references public.collections(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (collection_id, user_id)
);
create index collection_likes_user_id_idx on public.collection_likes(user_id);
alter table public.collection_likes enable row level security;
grant select on public.collection_likes to anon, authenticated;
grant insert, delete on public.collection_likes to authenticated;

create policy "Visible collection likes" on public.collection_likes
for select to anon, authenticated using (
  exists (select 1 from public.collections c where c.id = collection_id
    and (c.is_public or c.user_id = (select auth.uid())))
);
create policy "Users like visible collections" on public.collection_likes
for insert to authenticated with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.collections c where c.id = collection_id
      and (c.is_public or c.user_id = (select auth.uid()))
  )
);
create policy "Users remove own likes" on public.collection_likes
for delete to authenticated using (user_id = (select auth.uid()));

commit;
