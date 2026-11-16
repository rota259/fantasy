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
  insert into public.matches (venue_name, venue_address, teams, date_time, week) values ('ملعب الاختبار', 'بدر', array['نمور بدر', 'نمور بدر'], now() + interval '3 hours', 1);
  raise exception 'FAILED: match without my team';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
insert into public.matches (venue_name, venue_address, teams, date_time, week) values ('ملعب الاختبار', 'بدر', array['أسود بدر', 'نمور بدر'], now() + interval '3 hours', 1);
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
-- قبل يومين (ولو ده السبت = فاصل الجولتين → قبل ٣ أيام) عشان الاختبار ميقعش يوم الاتنين
select array['أسود بدر', 'نمور بدر'],
       case when extract(dow from (now() - interval '2 days') at time zone 'Africa/Cairo') = 6
            then now() - interval '3 days' else now() - interval '2 days' end - (g || ' hours')::interval, 1,
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

-- (التوثيق متجمّد في الإنتاج — هنا بنشغّله عشان نختبر قوانينه، وبنقفله تاني في الآخر)
create or replace function public.fn_venue_verify_required() returns boolean language sql immutable as $$ select true; $$;
-- ١٠) الملاعب: البطولة من صاحب ملعب موثّق بس · مكان الماتش · أخبار الملعب · التجديد والتقييم · أسطورة الملعب
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000002', 'host@t.co', jsonb_build_object('name', 'صاحب ملعب', 'phone', '0104', 'zone_id', (select id from public.zones where name = 'بدر')));
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
insert into public.venues (id, name, price, phone, owner_id, verified, zone_id)
values ('50000000-0000-0000-0000-000000000001', 'ملعب الحرية', 250, '01000000000', '00000000-0000-0000-0000-000000000002', true, 999);
reset role;
select t.check('owner cannot self-verify; zone from owner', (select not verified and zone_id = (select id from public.zones where name = 'بدر')
  from public.venues where id = '50000000-0000-0000-0000-000000000001'));
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
do $$ begin perform public.create_tournament('كاس الحرية', 'league', 3, 0, now() + interval '1 day', null, null, null, '50000000-0000-0000-0000-000000000001');
  raise exception 'FAILED: unverified venue tournament';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
do $$ begin perform public.verify_venue('50000000-0000-0000-0000-000000000001', true); raise exception 'FAILED: user verified';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select public.verify_venue('50000000-0000-0000-0000-000000000001', true);
reset role;
select t.check('owner told the venue is verified', exists (select 1 from public.notifications
  where user_id = '00000000-0000-0000-0000-000000000002' and title like '✅%' and link = 'venue:50000000-0000-0000-0000-000000000001'));
-- مدير منطقة مبيعملش بطولة في ملعب مش بتاعه
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
do $$ begin perform public.create_tournament('بطولة المدير', 'league', 3, 0, now() + interval '1 day', null, null, null, '50000000-0000-0000-0000-000000000001');
  raise exception 'FAILED: organizer used someone else venue';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
-- صاحب الملعب: بطولة → فرق → قرعة → ميعاد → لاعيبة → تشكيلة → أهداف
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
create temp table _v (id uuid);
insert into _v select public.create_tournament('كاس الحرية', 'league', 3, 0, now() + interval '1 day', null, null, null, '50000000-0000-0000-0000-000000000001');
select public.add_tournament_team((select id from _v), x) from unnest(array['أحرار ١', 'أحرار ٢', 'أحرار ٣']) x;
select public.draw_tournament((select id from _v));
select public.set_tournament_match_time(m.id, now() + interval '3 hours') from public.matches m where m.tournament_id = (select id from _v);
insert into public.players (name, team, position) values ('أسطورة الحرية', 'أحرار ١', 'FWD'), ('لاعب أحرار', 'أحرار ٢', 'FWD');
reset role;
select t.check('tournament at the venue, zone notified', (select venue_id = '50000000-0000-0000-0000-000000000001' from public.tournaments where id = (select id from _v))
  and exists (select 1 from public.notifications where title = '🏆 بطولة جديدة: كاس الحرية' and body like 'في ملعب الحرية%'));
select t.check('tournament matches: host organizes + venue filled', (select bool_and(organizer_id = '00000000-0000-0000-0000-000000000002'
  and venue_name = 'ملعب الحرية') from public.matches where tournament_id = (select id from _v)));
update public.matches set date_time = now() - interval '30 minutes'
where tournament_id = (select id from _v) and teams @> array['أحرار ١', 'أحرار ٢'];
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
insert into public.lineups (match_id, player_id, status)
select m.id, p.id, 'starting' from public.matches m, public.players p
where m.tournament_id = (select id from _v) and m.teams @> array['أحرار ١', 'أحرار ٢'] and p.team in ('أحرار ١', 'أحرار ٢');
insert into public.events (match_id, player_id, type, minute)
select m.id, p.id, 'goal', g from public.matches m, public.players p, generate_series(1, 3) g
where m.tournament_id = (select id from _v) and m.teams @> array['أحرار ١', 'أحرار ٢'] and p.name = 'أسطورة الحرية';
update public.matches set status = 'finished' where tournament_id = (select id from _v) and teams @> array['أحرار ١', 'أحرار ٢'];
reset role;
select t.check('host ran the match: 3 goals, finished', (select status = 'finished' and score_a + score_b = 3 from public.matches
  where tournament_id = (select id from _v) and teams @> array['أحرار ١', 'أحرار ٢']));
select t.check('venue legend + stats', (select (s->>'matches')::int = 1 and (s->>'goals')::int = 3 and (s->>'tournaments')::int = 1
  and s->'top'->0->>'name' = 'أسطورة الحرية' and (s->'top'->0->>'g')::int = 3 and s->'hours' <> '{}'::jsonb
  from public.venue_stats('50000000-0000-0000-0000-000000000001') s));
-- ماتش المدير لازم يبقى عليه ملعب
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
insert into public.teams (name) values ('نمور ٢');
do $$ begin
  insert into public.matches (teams, date_time, week) values (array['نمور بدر', 'نمور ٢'], now() + interval '3 hours', 1);
  raise exception 'FAILED: match without venue';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
insert into public.matches (teams, date_time, week, venue_id)
values (array['نمور بدر', 'نمور ٢'], now() + interval '3 hours', 1, '50000000-0000-0000-0000-000000000001');
reset role;
select t.check('venue name copied from the venue', exists (select 1 from public.matches
  where teams = array['نمور بدر', 'نمور ٢'] and venue_name = 'ملعب الحرية'));
-- تقييم قبل التجديد → التجديد → إشعار للمنطقة + التقييم من الأول
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
insert into public.venue_reviews (venue_id, user_id, stars)
values ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 2);
reset role;
select t.check('rated 2', (select avg = 2 from public.venue_ratings() where venue_id = '50000000-0000-0000-0000-000000000001'));
alter table public.venue_reviews disable trigger review_time;
update public.venue_reviews set created_at = now() - interval '1 day';
alter table public.venue_reviews enable trigger review_time;
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select public.post_venue_update('50000000-0000-0000-0000-000000000001', 'renovation', 'نجيلة جديدة وإضاءة LED');
do $$ begin perform public.post_venue_update('50000000-0000-0000-0000-000000000001', 'update', 'عرض الصبح');
  raise exception 'FAILED: 2 posts a day';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
select t.check('zone told about the renovation', exists (select 1 from public.notifications where audience = 'zone'
  and title = '🏟️ ملعب الحرية اتجدد' and link = 'venue:50000000-0000-0000-0000-000000000001'));
select t.check('old ratings out of the average',
  not exists (select 1 from public.venue_ratings() where venue_id = '50000000-0000-0000-0000-000000000001'));
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
update public.venue_reviews set stars = 5 where user_id = '00000000-0000-0000-0000-000000000001';
do $$ begin perform public.post_venue_update('50000000-0000-0000-0000-000000000001', 'update', 'حاجة');
  raise exception 'FAILED: user posted';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
select t.check('re-rated after renovation counts',
  (select avg = 5 from public.venue_ratings() where venue_id = '50000000-0000-0000-0000-000000000001'));
select t.check('owner told about the re-rating', (select count(*) = 2 from public.notifications
  where user_id = '00000000-0000-0000-0000-000000000002' and title like '⭐%'));

-- ١١) الكابتن (يوزر عادي) · فريق البطولة لكابتنه · المشرف بيوثّق اللاعيبة والملاعب
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000003', 'cap2@t.co', jsonb_build_object('name', 'كابتن يوزر', 'phone', '0105', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-000000000004', 'fan@t.co', jsonb_build_object('name', 'لاعب حقيقي', 'phone', '0106', 'zone_id', (select id from public.zones where name = 'بدر')));
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
insert into public.teams (name) values ('صقور الكابتن');
do $$ begin insert into public.teams (name) values ('فريق تاني للكابتن'); raise exception 'FAILED: user made 2 teams';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
insert into public.players (name, team, position) values ('حارس الصقور', 'صقور الكابتن', 'GK'), ('نجم الصقور', 'صقور الكابتن', 'FWD');
update public.players set nickname = 'النجم' where name = 'نجم الصقور';
do $$ begin insert into public.players (name, team, position) values ('دخيل', 'نمور بدر', 'FWD'); raise exception 'FAILED: captain used another team';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
select t.check('user captain owns a team + players', (select owner_id = '00000000-0000-0000-0000-000000000003' from public.teams where name = 'صقور الكابتن')
  and (select count(*) = 2 from public.players where team = 'صقور الكابتن') and exists (select 1 from public.players where nickname = 'النجم'));
-- المدير يعمل ماتش ضد فريق الكابتن → هو كابتن الخصم
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
insert into public.matches (teams, date_time, week, venue_name, venue_address)
values (array['نمور بدر', 'صقور الكابتن'], now() + interval '5 hours', 1, 'ملعب', 'بدر');
reset role;
select t.check('user captain = opponent captain', (select opp_captain = '00000000-0000-0000-0000-000000000003'
  from public.matches where teams = array['نمور بدر', 'صقور الكابتن']));
-- البطولة: فريق جديد بيتعمل باسم الكابتن اللي طلب
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
create temp table _v2 (id uuid);
insert into _v2 select public.create_tournament('كاس الكباتن', 'league', 4, 0, now() + interval '2 days', null, null, null, '50000000-0000-0000-0000-000000000001');
reset role;
insert into public.teams (name, zone_id) values ('فريق الشروق', (select id from public.zones where name = 'الشروق'));
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
select public.request_tournament_team((select id from _v2), 'فريق الحرية الجديد', '01011111111');
do $$ begin perform public.request_tournament_team((select id from _v2), 'نمور بدر', '01011111111'); raise exception 'FAILED: registered someone else team';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
do $$ begin perform public.request_tournament_team((select id from _v2), 'فريق الشروق', '01011111111'); raise exception 'FAILED: other zone team';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select public.review_tournament_team((select id from _v2), 'فريق الحرية الجديد', true);
reset role;
select t.check('approved team belongs to its captain', (select owner_id = '00000000-0000-0000-0000-000000000004'
  from public.teams where name = 'فريق الحرية الجديد'));
-- المشرف (يوزر ١ في بدر) بيوثّق لاعب
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
insert into public.player_claims (player_id, user_id) values ((select id from public.players where name = 'نجم الصقور'), '00000000-0000-0000-0000-000000000004');
reset role;
select t.check('supervisor told about the claim', exists (select 1 from public.notifications
  where user_id = '00000000-0000-0000-0000-000000000001' and title like '🪪%' and link = 'admin:claims'));
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.check('supervisor sees zone claims', (select count(*) = 1 from public.pending_claims()));
select public.review_claim((select id from public.pending_claims() limit 1), true);
reset role;
select t.check('claim approved by supervisor', (select user_id = '00000000-0000-0000-0000-000000000004'
  from public.players where name = 'نجم الصقور'));
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
do $$ begin perform public.pending_claims(); raise exception 'FAILED: plain user saw claims';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
-- صاحب الملعب يطلب التوثيق → المشرف يوثّق
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
insert into public.venues (id, name, price, phone, owner_id)
values ('50000000-0000-0000-0000-000000000002', 'ملعب الكابتن', 150, '01000000001', '00000000-0000-0000-0000-000000000003');
update public.venues set verify_requested_at = now() - interval '9 days' where id = '50000000-0000-0000-0000-000000000002';
select public.request_venue_verification('50000000-0000-0000-0000-000000000002');
do $$ begin perform public.request_venue_verification('50000000-0000-0000-0000-000000000002'); raise exception 'FAILED: request spam';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
do $$ begin perform public.verify_venue('50000000-0000-0000-0000-000000000002', true); raise exception 'FAILED: owner verified';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
select t.check('admin + supervisor told about the venue request', (select count(*) = 2 from public.notifications
  where title = '🏟️ طلب توثيق ملعب' and link = 'admin:venues'));
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.check('supervisor sees the venue request', (select count(*) = 1 from public.pending_venues()));
select public.verify_venue('50000000-0000-0000-0000-000000000002', true);
reset role;
select t.check('venue verified by supervisor', (select verified and verify_requested_at is null from public.venues
  where id = '50000000-0000-0000-0000-000000000002'));


-- ١٢) الكابتن يختار لاعيبة فريقه في الفانتازي عادي (منطقة الشروق — مفيش ماتشات فمحدش متقفل)
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000006', 'cap3@t.co', jsonb_build_object('name', 'كابتن الشروق', 'phone', '0107', 'zone_id', (select id from public.zones where name = 'الشروق')));
select t.as_user('00000000-0000-0000-0000-000000000006');
set role authenticated;
insert into public.teams (name) values ('ذئاب الشروق');
insert into public.players (name, team, position) values
 ('ذئب ١', 'ذئاب الشروق', 'GK'), ('ذئب ٢', 'ذئاب الشروق', 'FWD'), ('ذئب ٣', 'ذئاب الشروق', 'FWD'), ('ذئب ٤', 'ذئاب الشروق', 'FWD');
reset role;
insert into public.players (name, team, position) values
 ('فهد ١', 'فريق الشروق', 'FWD'), ('فهد ٢', 'فريق الشروق', 'FWD'), ('فهد ٣', 'فريق الشروق', 'FWD');
select t.as_user('00000000-0000-0000-0000-000000000006');
set role authenticated;
select public.save_round_picks(public.fn_open_round(), (select jsonb_agg(jsonb_build_object('player_id', id,
  'status', case when name in ('فهد ٢', 'فهد ٣') then 'bench' else 'starting' end,
  'is_captain', name = 'ذئب ٢', 'is_vice', name = 'ذئب ٣'))
  from public.players where team in ('ذئاب الشروق', 'فريق الشروق')));
reset role;
select t.check('captain picked his own players', (select count(*) = 4 from public.round_picks r join public.players p on p.id = r.player_id
  where r.user_id = '00000000-0000-0000-0000-000000000006' and p.team = 'ذئاب الشروق'));

-- ١٣) المدير بيدير ماتش بين فريقين كباتن · الكابتن بيبعت التشكيلة · لازم الكابتنين يأكّدوا
update public.profiles set created_at = now() - interval '30 days'
where id in ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000004');
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
insert into public.players (name, team, position) values
 ('صقر ٣', 'صقور الكابتن', 'FWD'), ('صقر ٤', 'صقور الكابتن', 'FWD'), ('صقر ٥', 'صقور الكابتن', 'FWD');
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
insert into public.matches (teams, date_time, week, venue_name, venue_address)
values (array['صقور الكابتن', 'فريق الحرية الجديد'], now() + interval '6 hours', 1, 'ملعب', 'بدر');
reset role;
create temp table _m3 as select id from public.matches where teams = array['صقور الكابتن', 'فريق الحرية الجديد'];
grant select on _m3 to authenticated;
select t.check('third-party organizer: both captains on the match', (select captains @> array[
  '00000000-0000-0000-0000-000000000003'::uuid, '00000000-0000-0000-0000-000000000004'::uuid] from public.matches where id = (select id from _m3))
  and (select count(*) = 2 from public.notifications where match_id = (select id from _m3) and title like '🤝 ماتش لفريقك%'));
-- الكابتن بيبعت تشكيلة فريقه
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
do $$ begin perform public.submit_team_lineup((select id from _m3), (select jsonb_agg(jsonb_build_object('player_id', id, 'status', 'starting'))
  from public.players where name in ('حارس الصقور', 'نجم الصقور'))); raise exception 'FAILED: 2 starters accepted';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
select public.submit_team_lineup((select id from _m3), (select jsonb_agg(jsonb_build_object('player_id', id, 'status', 'starting'))
  from public.players where team = 'صقور الكابتن'));
reset role;
select t.check('organizer told the lineup arrived', exists (select 1 from public.notifications
  where user_id = '00000000-0000-0000-0000-00000000000c' and link = 'manage:' || (select id from _m3)));
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
do $$ begin perform public.apply_team_lineup((select id from _m3), 'صقور الكابتن'); raise exception 'FAILED: captain applied';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
select public.apply_team_lineup((select id from _m3), 'صقور الكابتن');
reset role;
select t.check('captain lineup applied (5 starters)', (select count(*) = 5 from public.lineups where match_id = (select id from _m3) and status = 'starting'));
-- الماتش خلص → كابتن واحد مش كفاية → التاني أكّد = معتمد
update public.matches set date_time = now() - interval '70 minutes' where id = (select id from _m3);
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
update public.matches set status = 'finished' where id = (select id from _m3);
reset role;
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
select t.check('one captain is not enough', public.review_match((select id from _m3), true) = 'ok');
reset role;
select t.check('still pending', (select review_status = 'pending' from public.matches where id = (select id from _m3)));
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
select public.review_match((select id from _m3), true);
reset role;
select t.check('both captains confirmed = approved', (select review_status = 'approved' from public.matches where id = (select id from _m3)));

-- ١٤) التوثيق متجمّد: صاحب ملعب مش موثّق يعمل بطولة ويعلن
create or replace function public.fn_venue_verify_required() returns boolean language sql immutable as $$ select false; $$;
select t.as_user('00000000-0000-0000-0000-000000000006');
set role authenticated;
insert into public.venues (id, name, price, phone, owner_id)
values ('50000000-0000-0000-0000-000000000003', 'ملعب الذئاب', 150, '01000000002', '00000000-0000-0000-0000-000000000006');
create temp table _v3 (id uuid);
insert into _v3 select public.create_tournament('كاس الذئاب', 'league', 3, 0, now() + interval '1 day', null, null, null, '50000000-0000-0000-0000-000000000003');
select public.post_venue_update('50000000-0000-0000-0000-000000000003', 'update', 'عرض الافتتاح');
reset role;
select t.check('frozen verification: unverified owner made a tournament + announced',
  exists (select 1 from public.tournaments where id = (select id from _v3))
  and exists (select 1 from public.notifications where title = '📣 جديد في ملعب الذئاب'));


-- ١٥) صاحب الملعب بيأكّد إن الماتش اتلعب (شرط زي الكباتن) · تفكير الكابتن بالتشكيلة
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
insert into public.matches (teams, date_time, week, venue_id)
values (array['صقور الكابتن', 'فريق الحرية الجديد'], now() + interval '7 hours', 1, '50000000-0000-0000-0000-000000000001');
reset role;
create temp table _m4 as select id from public.matches where venue_id = '50000000-0000-0000-0000-000000000001' and tournament_id is null
  and teams = array['صقور الكابتن', 'فريق الحرية الجديد'];
grant select on _m4 to authenticated;
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
select public.remind_team_lineup((select id from _m4), 'صقور الكابتن');
do $$ begin perform public.remind_team_lineup((select id from _m4), 'صقور الكابتن'); raise exception 'FAILED: remind spam';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
select t.check('captain reminded, opens his team', exists (select 1 from public.notifications
  where user_id = '00000000-0000-0000-0000-000000000003' and title like '⏰ المدير مستني تشكيلة%' and link = 'captain'));
update public.matches set date_time = now() - interval '70 minutes' where id = (select id from _m4);
select t.as_user('00000000-0000-0000-0000-00000000000c');
set role authenticated;
update public.matches set status = 'finished' where id = (select id from _m4);
reset role;
select t.check('venue owner asked', exists (select 1 from public.notifications
  where user_id = '00000000-0000-0000-0000-000000000002' and title like '🏟️ الماتش ده اتلعب%' and match_id = (select id from _m4)));
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
select public.review_match((select id from _m4), true);
reset role;
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
select public.review_match((select id from _m4), true);
reset role;
select t.check('both captains ok but venue owner not yet = pending', (select review_status = 'pending' from public.matches where id = (select id from _m4)));
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
do $$ begin perform public.venue_confirm_match((select id from _m4), true); raise exception 'FAILED: non-owner confirmed';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select t.check('owner sees it pending', (select count(*) = 1 from public.venue_pending_matches('50000000-0000-0000-0000-000000000001')));
select public.venue_confirm_match((select id from _m4), true);
reset role;
select t.check('venue owner confirmed = approved', (select review_status = 'approved' and venue_ok from public.matches where id = (select id from _m4)));

-- ١٦) مشرف المنطقة بيوافق على طلب مدير
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000007', 'want@t.co', jsonb_build_object('name', 'عايز أبقى مدير', 'phone', '0108', 'zone_id', (select id from public.zones where name = 'بدر')));
select t.as_user('00000000-0000-0000-0000-000000000007');
set role authenticated;
insert into public.organizer_requests (user_id, note) values ('00000000-0000-0000-0000-000000000007', 'عندي ملعب');
reset role;
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.check('supervisor sees zone manager requests', (select count(*) = 1 from public.pending_organizer_requests()));
select public.review_organizer_request((select id from public.pending_organizer_requests() limit 1), true);
reset role;
select t.check('supervisor approved a manager', (select role = 'organizer' from public.profiles where id = '00000000-0000-0000-0000-000000000007'));

-- ١٧) محضرش الحجز مرتين = الحجز موقوف
insert into public.bookings (venue_id, user_id, day, hour, status) values
 ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004', current_date - 1, 18, 'confirmed'),
 ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004', current_date - 2, 19, 'confirmed');
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select public.set_booking_status(b.id, 'no_show') from public.bookings b
where b.user_id = '00000000-0000-0000-0000-000000000004' and b.status = 'confirmed';
reset role;
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
do $$ begin insert into public.bookings (venue_id, user_id, day, hour, status)
  values ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004', current_date + 1, 20, 'pending');
  raise exception 'FAILED: no-show user booked';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
select public.log_share('match');
reset role;
select t.check('no-shows counted + user told', public.fn_no_shows('00000000-0000-0000-0000-000000000004') = 2
  and exists (select 1 from public.notifications where user_id = '00000000-0000-0000-0000-000000000004' and title like '🚫%'));

-- ١٨) لوحة النمو
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select t.check('growth: Badr has matches + a share', (select matches_week > 0 and shares_week = 1 and users > 0
  from public.admin_growth() where zone_name = 'بدر'));
reset role;
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
do $$ begin perform public.admin_growth(); raise exception 'FAILED: user saw growth';
exception when others then if sqlerrm like 'FAILED%' then raise; end if; end $$;
reset role;

-- ١٩) بروفايل اللاعب: ماتشاته وعمل إيه فيها
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.check('player profile lists his match: team, starter, 3 goals', (select count(*) = 1
  and bool_and(team = 'أحرار ١' and lineup = 'starting' and goals = 3 and points > 0
               and items::text like '%جول%' and teams @> array['أحرار ١', 'أحرار ٢'])
  from public.player_matches((select id from public.players where name = 'أسطورة الحرية'))));
reset role;

