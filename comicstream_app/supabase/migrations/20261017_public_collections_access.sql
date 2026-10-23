-- Public collections can be viewed by anyone using the app. Only the owner
-- can create, edit, remove a collection, or change its items.
alter table public.collections enable row level security;
alter table public.collection_items enable row level security;

drop policy if exists "Public collections and owned collections are readable" on public.collections;
create policy "Public collections and owned collections are readable"
on public.collections for select
to anon, authenticated
using (is_public or user_id = (select auth.uid()));

drop policy if exists "Users create their own collections" on public.collections;
create policy "Users create their own collections"
on public.collections for insert
to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Users update their own collections" on public.collections;
create policy "Users update their own collections"
on public.collections for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "Users delete their own collections" on public.collections;
create policy "Users delete their own collections"
on public.collections for delete
to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Public collection items are readable" on public.collection_items;
create policy "Public collection items are readable"
on public.collection_items for select
to anon, authenticated
using (
  exists (
    select 1 from public.collections
    where collections.id = collection_items.collection_id
      and (collections.is_public or collections.user_id = (select auth.uid()))
  )
);

drop policy if exists "Owners manage their collection items" on public.collection_items;
create policy "Owners manage their collection items"
on public.collection_items for all
to authenticated
using (
  exists (
    select 1 from public.collections
    where collections.id = collection_items.collection_id
      and collections.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.collections
    where collections.id = collection_items.collection_id
      and collections.user_id = (select auth.uid())
  )
);
