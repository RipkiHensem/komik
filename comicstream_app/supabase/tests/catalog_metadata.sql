-- Run as postgres in SQL Editor. All test writes roll back.
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"email":"non-admin-test@example.invalid","role":"authenticated"}', true);
do $$ begin
  begin
    insert into public.chapter_metadata_overrides values ('__yomu_rls_probe__','__probe__','Probe',1,null);
    raise exception 'Non-admin write unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
end $$;
select set_config('request.jwt.claims', '{"email":"rhifqi.syahputra@gmail.com","role":"authenticated"}', true);
insert into public.chapter_metadata_overrides values ('__yomu_rls_probe__','__probe__','Probe',1,null);
update public.chapter_metadata_overrides set title='Edited' where chapter_id='__yomu_rls_probe__';
do $$ begin
  if not exists (select 1 from public.chapter_metadata_overrides where chapter_id='__yomu_rls_probe__' and title='Edited') then
    raise exception 'Admin edit failed';
  end if;
end $$;
rollback;
