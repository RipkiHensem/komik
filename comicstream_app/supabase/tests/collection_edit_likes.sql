-- Transactional checks: no test collection or likes survive rollback.
begin;
do $$
declare
  owner_id uuid;
  other_id uuid;
  target_id uuid;
  affected int;
begin
  select id into owner_id from auth.users order by id limit 1;
  select id into other_id from auth.users where id <> owner_id order by id limit 1;
  if other_id is null then raise exception 'Two existing users required'; end if;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  execute 'set local role authenticated';
  insert into public.collections(user_id, name, is_public)
    values(owner_id, 'Repository verification', true) returning id into target_id;
  update public.collections set name = 'Edited', description = 'Verified'
    where id = target_id;
  get diagnostics affected = row_count;
  assert affected = 1, 'Owner must be able to edit';
  insert into public.collection_likes(collection_id, user_id) values(target_id, owner_id);
  begin
    insert into public.collection_likes(collection_id, user_id) values(target_id, owner_id);
    raise exception 'Duplicate like accepted';
  exception when unique_violation then null;
  end;

  perform set_config('request.jwt.claim.sub', other_id::text, true);
  update public.collections set name = 'Forbidden' where id = target_id;
  get diagnostics affected = row_count;
  assert affected = 0, 'Non-owner cannot edit';
  delete from public.collection_likes where collection_id = target_id;
  get diagnostics affected = row_count;
  assert affected = 0, 'Cannot remove another account like';
  insert into public.collection_likes(collection_id, user_id) values(target_id, other_id);
  delete from public.collection_likes where collection_id = target_id and user_id = other_id;
  get diagnostics affected = row_count;
  assert affected = 1, 'Can undo own like';

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  update public.collections set is_public = false where id = target_id;
  perform set_config('request.jwt.claim.sub', other_id::text, true);
  assert (select count(*) from public.collection_likes where collection_id = target_id) = 0,
    'Private collection likes hidden from other accounts';
  begin
    insert into public.collection_likes(collection_id, user_id) values(target_id, other_id);
    raise exception 'Private collection like accepted';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
end $$;
rollback;
select 'Owner edit, unauthorized edit, duplicate like, undo, and private access passed' as result;
