-- سيناريو كامل في مدينة بدر (بالقوانين الحقيقية): مدير يعمل فريقين وماتش ويسجّل تشكيلة وأهداف ويقفل الماتش ←
-- ٤ ساعات من غير اعتراض ← الماتش يتعتمد لوحده ← لاعيبته يظهروا في تشكيلة الجولة الحالية ونجمها.
create schema t;
grant usage on schema t to anon, authenticated;
create function t.check(label text, ok boolean) returns void language plpgsql as $$
begin
  if not coalesce(ok, false) then raise exception 'FAILED: %', label; end if;
  raise notice 'OK %', label;
end $$;
create function t.as_user(u uuid) returns void language sql as $$ select set_config('request.jwt.claim.sub', u::text, false); $$;
grant execute on all functions in schema t to anon, authenticated;

insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-00000000000a', 'admin@t.co', jsonb_build_object('name', 'أدمن', 'phone', '0100', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-00000000000b', 'org@t.co', jsonb_build_object('name', 'مدير بدر', 'phone', '0101', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-00000000000c', 'cap@t.co', jsonb_build_object('name', 'كابتن النمور', 'phone', '0103', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-000000000001', 'u1@t.co', jsonb_build_object('name', 'يوزر بدر', 'phone', '0102', 'zone_id', (select id from public.zones where name = 'بدر')));
update public.profiles set role = 'manager' where id = '00000000-0000-0000-0000-00000000000a';
update public.profiles set role = 'organizer' where id in ('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000c');

-- ١) المدير: فريقين + لاعيبة + ماتش بعد ٣ ساعات
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into public.teams (name) values ('أسود بدر'), ('فريق تاني ليا');
insert into public.players (name, team, position) values
 ('حارس الأسود', 'أسود بدر', 'GK'), ('هداف الأسود', 'أسود بدر', 'FWD'), ('لاعب أسود ٢', 'أسود بدر', 'FWD');
reset role;
-- كابتن تاني بفريقه ولاعيبته
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
insert into public.teams (name) values ('نمور بدر');
insert into public.players (name, team, position) values
 ('حارس النمور', 'نمور بدر', 'GK'), ('هداف النمور', 'نمور بدر', 'FWD'), ('لاعب نمور ٢', 'نمور بدر', 'FWD');
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
do $$ begin
  insert into public.matches (teams, date_time, week) values (array['نمور بدر', 'نمور بدر'], now() + interval '3 hours', 1);
  raise exception 'FAILED: match without my team';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
insert into public.matches (teams, date_time, week) values (array['أسود بدر', 'نمور بدر'], now() + interval '3 hours', 1);
reset role;
select t.check('match + players landed in Badr', (select m.zone_id = (select id from public.zones where name = 'بدر') from public.matches m)
  and (select bool_and(zone_id = (select id from public.zones where name = 'بدر')) from public.players));
select t.check('opponent captain set + notified', (select opp_captain = '00000000-0000-0000-0000-00000000000c' from public.matches)
  and exists (select 1 from public.notifications where user_id = '00000000-0000-0000-0000-00000000000c' and title like '🤝%'));
select t.check('zone told about the new match', (select count(*) = 1 from public.notifications where title like 'ماتش جديد في منطقتك%'));

-- ٢) الماتش اتلعب (بنرجّع ميعاده لورا بصلاحيات السيرفر): تشكيلة + أهداف + المدير يقفله
update public.matches set date_time = now() - interval '70 minutes';
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into public.lineups (match_id, player_id, status) select (select id from public.matches), id, 'starting' from public.players;
insert into public.events (match_id, player_id, type, minute) select (select id from public.matches), id, 'goal', 10 from public.players where name = 'هداف الأسود';
insert into public.events (match_id, player_id, type, minute) select (select id from public.matches), id, 'goal', 20 from public.players where name = 'هداف الأسود';
insert into public.events (match_id, player_id, type, minute) select (select id from public.matches), id, 'goal', 30 from public.players where name = 'هداف النمور';
update public.matches set status = 'finished';
reset role;
select t.check('result from the goals: 2-1', (select score_a = 2 and score_b = 1 from public.matches));
select t.check('waiting for approval (4 hours)', (select review_status = 'pending' and review_due between now() + interval '3 hours 59 minutes' and now() + interval '4 hours 1 minute' from public.matches));

-- ٣) قبل الاعتماد: لايف تشكيلة الجولة فاضية (بتعدّ المعتمد بس)
select t.check('before approval: live TOTW empty', (select count(*) = 0 from public.player_points_approved(public.fn_round_from(public.fn_week_cutoff(now())), public.fn_week_cutoff(now()), (select id from public.zones where name = 'بدر'))));

-- ٤) عدّت ٤ ساعات: المدير جديد (أقل من ٥ معتمدة) → مبيتعتمدش لوحده، والأدمن بيتبلّغ
update public.matches set review_due = now() - interval '1 minute', finished_at = now() - interval '4 hours 1 minute';
select public.fn_close_due_matches_and_season();
select t.check('new organizer: not auto-approved', (select review_status = 'pending' from public.matches));
select t.check('admin nudged', exists (select 1 from public.notifications where user_id = '00000000-0000-0000-0000-00000000000a' and title like '%مستني اعتمادك%'));
select t.check('captain sees it in pending reviews', (select count(*) = 1 from public.matches m
  where public.fn_reviewer_team(m.id, '00000000-0000-0000-0000-00000000000c') = 'نمور بدر'));
-- كابتن حسابه جديد (أقل من ٧ أيام) → تأكيده مبيعتمدش لوحده
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
select public.review_match((select id from public.matches), true);
reset role;
select t.check('fresh captain: still pending + flagged', (select review_status = 'pending' and 'fresh_captain' = any(flags) from public.matches));
-- مشرف المنطقة (يوزر عادي) يعتمد ماتشات منطقته
update public.profiles set supervisor_zone = (select id from public.zones where name = 'بدر') where id = '00000000-0000-0000-0000-000000000001';
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.check('supervisor sees it in queue', (select count(*) = 1 from public.admin_review_queue()));
reset role;
-- الكابتن قديم → تأكيده = اعتماد فوري
update public.profiles set created_at = now() - interval '30 days' where id = '00000000-0000-0000-0000-00000000000c';
update public.matches set flags = array_remove(flags, 'fresh_captain');
delete from public.match_reviews;
-- كابتن الخصم يأكّد → اعتماد فوري
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
select t.check('captain confirms', public.review_match((select id from public.matches), true) in ('ok', 'approved'));
reset role;
select t.check('approved by opponent captain', (select review_status = 'approved' from public.matches));

-- ٥) بعد الاعتماد: لاعيبته في تشكيلة الجولة الحالية، والنجم = هداف الأسود (٢ جول + مشاركة)
create temp table _top as select * from public.player_points_approved(public.fn_round_from(public.fn_week_cutoff(now())), public.fn_week_cutoff(now()), (select id from public.zones where name = 'بدر'));
select t.check('after approval: Badr players show up', (select count(*) >= 5 from _top));
select t.check('star of the round = هداف الأسود with 13 (2 goals ×5 + appearance 3)', (select name = 'هداف الأسود' and points = 13 from _top order by points desc, name limit 1));
select t.check('keeper of the winning side has the clean sheet (3 + 8 = 11)', (select points = 11 from _top where name = 'حارس الأسود'));

-- ٦) سقف الماتش: ٦ أهداف = بتتحسب ٥، والمجموع لحد ٢٥
select t.check('cap: 8 goals FWD capped at 25', public.fn_score_points('FWD', 8, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, true) = 25);
select t.check('cap: goals past 5 ignored (2 goals still 10+3)', public.fn_score_points('FWD', 2, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, true) = 13);
select t.check('items sum = capped points', (select sum((x->>'p')::int) = 25 from jsonb_array_elements(
  public.fn_score_items('FWD', 8, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, true)) x));

-- ٧) مصداقية: ٣ ماتشات تتلغي = إيقاف
select t.check('trust visible', (public.organizer_trust('00000000-0000-0000-0000-00000000000b')->>'approved')::int = 1
  and not (public.organizer_trust('00000000-0000-0000-0000-00000000000b')->>'trusted')::boolean);
insert into public.matches (teams, date_time, week, organizer_id, status)
select array['أسود بدر', 'نمور بدر'], now() - interval '2 days' - (g || ' hours')::interval, 1,
       '00000000-0000-0000-0000-00000000000b', 'upcoming' from generate_series(1, 3) g;
update public.matches set status = 'finished' where status = 'upcoming';
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select public.resolve_match(id, 'void') from (select id from public.matches where review_status <> 'approved' order by date_time limit 2) x;
reset role;
select t.check('2 strikes, still active', (select strikes = 2 and is_active from public.profiles where id = '00000000-0000-0000-0000-00000000000b'));
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select public.resolve_match(id, 'void') from (select id from public.matches where review_status not in ('approved', 'void') limit 1) x;
reset role;
select t.check('3rd strike = banned + all matches void', (select not is_active from public.profiles where id = '00000000-0000-0000-0000-00000000000b')
  and not exists (select 1 from public.matches where organizer_id = '00000000-0000-0000-0000-00000000000b' and review_status <> 'void'));

-- ٨) الأسامي المتشابهة
insert into public.players (name, team, position, nickname) values ('هداف الأسود', 'نمور بدر', 'FWD', ' حمو ');
select t.check('nickname trimmed', exists (select 1 from public.players where nickname = 'حمو'));
select t.check('same first name in zone → name_dup on both', (select count(*) >= 2 from public.players where name_dup and name = 'هداف الأسود'));
insert into public.players (name, team, position) values ('زيكو', 'نمور بدر', 'FWD');
select t.check('unique name not flagged', (select not name_dup from public.players where name = 'زيكو'));
select t.check('same first name keepers flagged', (select bool_and(name_dup) from public.players where name like 'حارس %'));
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
select t.check('similar_players finds both', (select count(*) = 2 from public.similar_players('هداف  الأسود', 'نمور بدر')));
update public.players set name_dup = false where name = 'هداف الأسود';
reset role;
select t.check('client cannot clear name_dup', (select bool_and(name_dup) from public.players where name = 'هداف الأسود'));

-- ٩) المشرف ميقدرش يحكم في ماتشات منطقة تانية، واليوزر العادي مالوش طابور
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
do $$ begin perform public.admin_review_queue(); raise exception 'FAILED: non-supervisor queue';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
