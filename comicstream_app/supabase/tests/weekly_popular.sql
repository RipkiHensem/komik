begin;
set local role anon;
select public.record_comic_read('yomu-test-weekly-20261109','Manhwa','11111111-1111-4111-8111-111111111111');
select public.record_comic_read('yomu-test-weekly-20261109','Manhwa','11111111-1111-4111-8111-111111111111');
select public.record_comic_read('yomu-test-weekly-20261109','Manhwa','22222222-2222-4222-8222-222222222222');
do $$begin
 if (select weekly_readers from public.weekly_popular_comics('Manhwa') where comic_id='yomu-test-weekly-20261109') is distinct from 2::bigint then raise exception 'Unique reader count failed'; end if;
 if exists(select 1 from public.weekly_popular_comics('Manga') where comic_id='yomu-test-weekly-20261109') then raise exception 'Format filter failed'; end if;
 if has_table_privilege('anon','yomu_private.comic_readers','SELECT') then raise exception 'Reader identifiers exposed'; end if;
end $$;
reset role;
update yomu_private.comic_readers set last_read_at=now()-interval '7 days' where comic_id='yomu-test-weekly-20261109';
do $$begin
 if exists(select 1 from public.weekly_popular_comics(null) where comic_id='yomu-test-weekly-20261109') then raise exception 'Seven day boundary failed'; end if;
end $$;
set local role anon;
select public.record_comic_read('yomu-test-weekly-20261109','Manhwa','11111111-1111-4111-8111-111111111111');
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
select public.record_comic_read('yomu-test-weekly-20261109','Manhwa','11111111-1111-4111-8111-111111111111');
do $$begin
 if (select weekly_readers from public.weekly_popular_comics('Manhwa') where comic_id='yomu-test-weekly-20261109') is distinct from 1::bigint then raise exception 'Guest login counted twice'; end if;
end $$;
reset role;
select 'PASS: unique readers, type filter, seven-day cutoff, private identities, guest login deduplication; all fixtures rolled back' as result;
rollback;
