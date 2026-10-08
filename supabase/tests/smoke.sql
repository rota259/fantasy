-- اختبار جولة كاملة: أدمن + مدير منطقة + يوزرز من منطقتين + محاولات غش
create schema t;
grant usage on schema t to anon, authenticated;

-- بيشغّل SQL ولازم يفشل (بصلاحيات اللي ناداه) — ولو نجح يبقى ثغرة
create function t.expect_fail(label text, q text) returns void language plpgsql as $$
begin
  begin
    execute q;
  exception when others then
    raise notice 'OK (blocked) %: %', label, sqlerrm;
    return;
  end;
  raise exception 'SECURITY HOLE: % succeeded', label;
end $$;
grant execute on function t.expect_fail(text, text) to anon, authenticated;

create function t.check(label text, ok boolean) returns void language plpgsql as $$
begin
  if not coalesce(ok, false) then raise exception 'FAILED: %', label; end if;
  raise notice 'OK %', label;
end $$;
grant execute on function t.check(text, boolean) to anon, authenticated;

create function t.as_user(u uuid) returns void language sql as $$
  select set_config('request.jwt.claim.sub', u::text, false);
$$;
grant execute on function t.as_user(uuid) to anon, authenticated;

-- تشكيلة الجولة: كام حارس وكام لاعب من المرشّحين
create function t.totw_pick(gks int, others int) returns uuid[] language sql as $$
  select array(
    (select (c->>'id')::uuid from public.admin_totw_candidates(public.fn_week_cutoff(now()) - interval '7 days') a,
            jsonb_array_elements(a.candidates) c where c->>'position' = 'GK' limit gks)
    union all
    (select (c->>'id')::uuid from public.admin_totw_candidates(public.fn_week_cutoff(now()) - interval '7 days') a,
            jsonb_array_elements(a.candidates) c where c->>'position' <> 'GK' limit others));
$$;
grant execute on function t.totw_pick(int, int) to authenticated;

-- ── اليوزرز (البروفايل بيتعمل من trigger التسجيل) ──
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-00000000000a', 'admin@t.co', jsonb_build_object('name', 'أدمن', 'phone', '0100', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-00000000000b', 'org@t.co',   jsonb_build_object('name', 'مدير', 'phone', '0101', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-000000000001', 'u1@t.co',    jsonb_build_object('name', 'يوزر١', 'phone', '0102', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-000000000002', 'u2@t.co',    jsonb_build_object('name', 'يوزر٢', 'phone', '0103', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-000000000003', 'u3@t.co',    jsonb_build_object('name', 'يوزر٣', 'phone', '0104', 'zone_id', (select id from public.zones where name = 'الشروق')));
select t.check('profiles created by signup trigger', (select count(*) = 5 from public.profiles));
update public.profiles set role = 'manager' where id = '00000000-0000-0000-0000-00000000000a';

-- ── الغش من يوزر عادي ──
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.expect_fail('call internal fn_set_badge', $q$select public.fn_set_badge('00000000-0000-0000-0000-000000000001', 'record', 99)$q$);
select t.expect_fail('call internal fn_leave_fantasy', $q$select public.fn_leave_fantasy('00000000-0000-0000-0000-000000000002')$q$);
select t.expect_fail('call internal fn_admin_log', $q$select public.fn_admin_log('x', 'y', '{}')$q$);
select t.expect_fail('call fn_tick', $q$select public.fn_tick(300)$q$);
select t.expect_fail('make myself admin via rpc', $q$select public.set_user_role('00000000-0000-0000-0000-000000000001', 'manager')$q$);
update public.profiles set total_points = 999, role = 'manager', is_active = true where id = auth.uid();
select t.check('guard kept points/role', (select total_points = 0 and role = 'user' from public.profiles where id = auth.uid()));
select t.expect_fail('write notifications', $q$insert into public.notifications (title) values ('spam')$q$);
select t.expect_fail('write round points', $q$insert into public.user_round_points (user_id, round_end, points) values (auth.uid(), now(), 500)$q$);
reset role;

-- ── المدير: طلب → موافقة الأدمن ──
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into public.organizer_requests (user_id, note) values (auth.uid(), 'عايز أنظّم');
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select public.review_organizer_request((select id from public.organizer_requests limit 1), true);
reset role;
select t.check('organizer role granted', (select role = 'organizer' from public.profiles where id = '00000000-0000-0000-0000-00000000000b'));
select t.check('admin action logged', (select count(*) >= 1 from public.admin_log));

-- ── المدير يعمل فرقه ولاعيبته وماتش في الجولة المفتوحة ──
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into public.teams (name) values ('نسور بدر'), ('صقور بدر');
insert into public.players (name, team, position) values
 ('ح١', 'نسور بدر', 'GK'), ('د١', 'نسور بدر', 'DEF'), ('و١', 'نسور بدر', 'MID'), ('ه١', 'نسور بدر', 'FWD'), ('ه٢', 'نسور بدر', 'FWD'),
 ('ح٢', 'صقور بدر', 'GK'), ('د٢', 'صقور بدر', 'DEF'), ('و٢', 'صقور بدر', 'MID'), ('ه٣', 'صقور بدر', 'FWD'), ('ه٤', 'صقور بدر', 'FWD');
select t.expect_fail('organizer uses a team he does not own', $q$insert into public.players (name, team, position) values ('x', 'فريق حد تاني', 'FWD')$q$);
insert into public.matches (teams, date_time, week)
values (array['نسور بدر', 'صقور بدر'], public.fn_open_round() - interval '6 days', 1);
select t.expect_fail('organizer picks fantasy', $q$select public.save_round_picks(public.fn_open_round(), '[]'::jsonb)$q$);
reset role;
select t.check('match got the team zone', (select zone_id = (select id from public.zones where name = 'بدر') from public.matches limit 1));
select t.check('players got the team zone', (select bool_and(zone_id is not null) from public.players));
select t.check('new match broadcast to zone', (select count(*) >= 1 from realtime.sent where topic like 'zone:%'));

-- ── اليوزرز يعملوا تشكيلة الجولة ──
create function t.lineup() returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('player_id', id, 'status', st, 'is_captain', cap, 'is_vice', vic)) from (
    select id, case when name in ('ه٢', 'ه٤') then 'bench' else 'starting' end as st,
           name = 'ه١' as cap, name = 'و١' as vic
    from public.players where name in ('ح١', 'د١', 'و١', 'ه١', 'د٢', 'ه٢', 'ه٤')) x;
$$;
grant execute on function t.lineup() to authenticated;
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.expect_fail('lineup without vice captain', $q$select public.save_round_picks(public.fn_open_round(),
  (select jsonb_agg(e - 'is_vice') from jsonb_array_elements(t.lineup()) e))$q$);
select public.save_round_picks(public.fn_open_round(), t.lineup());
select t.check('others picks hidden before deadline', (select count(*) = 0 from public.round_picks where user_id <> auth.uid()));
reset role;
select t.check('lineup saved (7)', (select count(*) = 7 from public.round_picks where user_id = '00000000-0000-0000-0000-000000000001'));
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
select t.expect_fail('pick from another zone', $q$select public.save_round_picks(public.fn_open_round(), t.lineup())$q$);
reset role;

-- ── الماتش يتلعب: ننقله للجولة الشغّالة (بصلاحيات السيرفر) ونسجّل أحداث ──
update public.matches set date_time = now() - interval '30 minutes';
insert into public.round_picks (user_id, round_end, player_id, status, is_captain, is_vice)
select user_id, public.fn_week_cutoff(now()), player_id, status, is_captain, is_vice from public.round_picks;
insert into public.lineups (match_id, player_id, status)
select (select id from public.matches limit 1), id, 'starting' from public.players;
update public.players set user_id = '00000000-0000-0000-0000-000000000001' where name = 'د١';
update public.players set user_id = '00000000-0000-0000-0000-000000000002' where name = 'د٢';
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into public.events (match_id, player_id, type, minute)
select (select id from public.matches limit 1), id, 'goal', 10 from public.players where name = 'ه١';
reset role;
select t.check('captain goal = 10 live points (5×2)',
  (select points = 10 and final_points = 0 from public.user_round_points
   where user_id = '00000000-0000-0000-0000-000000000001' and round_end = public.fn_week_cutoff(now())));
select t.check('total not counted before approval', (select total_points = 0 from public.profiles where id = '00000000-0000-0000-0000-000000000001'));

-- ── المدير يقفل الماتش → تأكيد الفريقين → اعتماد ──
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
update public.matches set status = 'finished', score_a = 1, score_b = 0;
reset role;
select t.check('match pending review', (select review_status = 'pending' from public.matches limit 1));
select t.check('new organizer flagged', (select 'new_organizer' = any(flags) from public.matches limit 1));
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select public.review_match((select id from public.matches limit 1), true, null);
reset role;
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select public.review_match((select id from public.matches limit 1), true, null);
reset role;
select t.check('both teams confirmed → approved', (select review_status = 'approved' from public.matches limit 1));
select t.check('points counted after approval (+ GK clean sheet)', (select total_points = 18 from public.profiles where id = '00000000-0000-0000-0000-000000000001'));

-- ── الحظر ──
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select public.set_user_active('00000000-0000-0000-0000-000000000002', false);
reset role;
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select t.expect_fail('banned user saves lineup', $q$select public.save_round_picks(public.fn_open_round(), t.lineup())$q$);
select t.expect_fail('banned user creates league', $q$insert into public.leagues (name, type, owner_id) values ('x', 'private', auth.uid())$q$);
reset role;

-- ── حذف الحساب ──
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
select public.delete_my_account();
reset role;
select t.check('account deleted with profile', (select count(*) = 0 from public.profiles where id = '00000000-0000-0000-0000-000000000003'));

-- ── تشكيلة الجولة بموافقة الأدمن ──
insert into public.events (match_id, player_id, type)
select (select id from public.matches limit 1), id, 'assist' from public.players where name in ('ح١', 'د١', 'و١', 'ه٣', 'د٢');
-- الجولة اللي فاتت (خلصت): الماتش ليلة الجمعة ٦ الصبح قبل نهايتها — ميعاد ثابت مش بيقع في فاصل السبت
update public.matches set date_time = public.fn_week_cutoff(now()) - interval '7 days 2 hours';
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select t.check('admin sees zone candidates',
  (select count(*) >= 1 from public.admin_totw_candidates((public.fn_week_cutoff(now()) - interval '7 days'))));
select t.expect_fail('totw with two goalkeepers', $q$select public.publish_totw(public.fn_week_cutoff(now()) - interval '7 days',
  (select id from public.zones where name = 'بدر'), t.totw_pick(2, 3))$q$);
select public.publish_totw((public.fn_week_cutoff(now()) - interval '7 days'),
  (select id from public.zones where name = 'بدر'), t.totw_pick(1, 4));
reset role;
select t.check('totw published for the zone', (select count(*) = 1 from public.team_of_week));
select t.check('totw star = GK (clean sheet 8 + assist 3)', (select (players->0->>'name') = 'ح١' from public.team_of_week));

-- ── قواعد النقط ──
select t.check('4 goals FWD = 3×5 + 7 + hat-trick 6 = 28', public.fn_score_points('FWD', 4, 0, 0, 0, 0, 0, 0, 0, 0, false) = 28);
select t.check('GK goal = 8', public.fn_score_points('GK', 1, 0, 0, 0, 0, 0, 0, 0, 0, false) = 8);
select t.check('4 assists = 3×3 + 5 + bonus 4 = 18', public.fn_score_points('MID', 0, 4, 0, 0, 0, 0, 0, 0, 0, false) = 18);
select t.check('7 saves = 1 · 10 tackles = 2', public.fn_score_points('GK', 0, 0, 7, 0, 0, 10, 0, 0, 0, false) = 3);
select t.check('penalty save 4 · clean sheet 8', public.fn_score_points('GK', 0, 0, 0, 1, 0, 0, 0, 0, 0, true) = 12);
select t.check('penalty miss -3 · insult -5 · own goal -2 · motm +3',
  public.fn_score_points('DEF', 0, 0, 0, 0, 1, 0, 1, 1, 1, false) = -7);

-- ── ماتش بعد الديدلاين: المدير بيطلب والأدمن بيوافق ──
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
select t.expect_fail('late request while round open',
  $q$select public.request_late_match(array['نسور بدر', 'صقور بدر'], public.fn_open_round() + interval '2 days')$q$);
select t.expect_fail('late request with foreign team',
  $q$select public.request_late_match(array['نسور بدر', 'فريق حد تاني'], public.fn_week_cutoff(now()) - interval '1 minute')$q$);
select t.expect_fail('organizer inserts match after deadline',
  $q$insert into public.matches (teams, date_time) values (array['نسور بدر', 'صقور بدر'], public.fn_week_cutoff(now()) - interval '1 minute')$q$);
select t.expect_fail('organizer approves a request', $q$select public.review_late_match(gen_random_uuid(), true)$q$);
select t.expect_fail('organizer writes request table directly',
  $q$insert into public.late_match_requests (organizer_id, teams, date_time) values (auth.uid(), array['أ', 'ب'], now())$q$);
select public.request_late_match(array['نسور بدر', 'صقور بدر'], public.fn_week_cutoff(now()) - interval '1 minute', 'الملعب اتأجل');
reset role;
select t.check('admins notified of late request', (select count(*) >= 1 from public.notifications where title like '⏰%'));
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select t.check('admin sees late request', (select count(*) = 1 from public.admin_late_match_requests()));
select public.review_late_match((select id from public.admin_late_match_requests() limit 1), true);
insert into public.matches (teams, date_time) values (array['أ', 'ب'], public.fn_week_cutoff(now()) - interval '2 minutes');
reset role;
select t.check('late match created for organizer',
  (select organizer_id = '00000000-0000-0000-0000-00000000000b' and zone_id is not null
   from public.matches where id = (select match_id from public.late_match_requests limit 1)));
select t.check('admin adds match after deadline directly', (select count(*) = 1 from public.matches where teams = array['أ', 'ب']));

-- ── مواعيد الجولة: [السبت ٤ العصر , السبت اللي بعده ٨ الصبح] · الديدلاين السبت ١٢ الضهر ──
create function t.cairo(x text) returns timestamptz language sql as $$ select x::timestamp at time zone 'Africa/Cairo' $$;
select t.check('Fri night match ends round at Sat 08:00', public.fn_week_cutoff(t.cairo('2026-10-03 07:59')) = t.cairo('2026-10-03 08:00'));
select t.check('Sat 16:00 match is next round', public.fn_week_cutoff(t.cairo('2026-10-03 16:00')) = t.cairo('2026-10-10 08:00'));
select t.check('round start Sat 16:00', public.fn_round_start(t.cairo('2026-10-10 08:00')) = t.cairo('2026-10-03 16:00'));
select t.check('deadline Sat 15:00', public.fn_round_deadline(t.cairo('2026-10-10 08:00')) = t.cairo('2026-10-03 15:00'));
select t.check('Sat 10:00 is the gap', public.fn_in_round_gap(t.cairo('2026-10-03 10:00')));
select t.check('Sat 08:00 / 16:00 / Fri 10:00 not gap', not public.fn_in_round_gap(t.cairo('2026-10-03 08:00'))
  and not public.fn_in_round_gap(t.cairo('2026-10-03 16:00')) and not public.fn_in_round_gap(t.cairo('2026-10-02 10:00')));
select t.expect_fail('match in the gap (even admin)',
  $q$insert into public.matches (teams, date_time) values (array['س', 'ص'], t.cairo('2026-10-03 10:00'))$q$);

-- ── تحدّي الجولة: كل مدير من ماتشاته · لأهل منطقته بس · فرق الأهداف ──
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000004', 'u4@t.co', jsonb_build_object('name', 'يوزر٤', 'phone', '0105', 'zone_id', (select id from public.zones where name = 'الشروق')));
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into public.matches (teams, date_time, week) values (array['نسور بدر', 'صقور بدر'], public.fn_open_round() - interval '5 days', 2);
insert into public.matches (teams, date_time, week) values (array['صقور بدر', 'نسور بدر'], public.fn_open_round() - interval '4 days', 2);
reset role;
create function t.ch() returns uuid language sql as $$ select id from public.matches where week = 2 order by date_time limit 1 $$;
grant execute on function t.ch() to authenticated;
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.expect_fail('predict before challenge', $q$insert into public.predictions (user_id, match_id, score_a, score_b) values (auth.uid(), t.ch(), 1, 0)$q$);
select t.expect_fail('user sets challenge', $q$select public.set_challenge(t.ch())$q$);
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
select public.set_challenge(t.ch());
select t.expect_fail('second challenge same round same organizer',
  $q$select public.set_challenge((select id from public.matches where week = 2 order by date_time desc limit 1))$q$);
reset role;
select t.check('challenge notification to the zone only',
  (select audience = 'zone' and zone_id = (select id from public.zones where name = 'بدر')
   from public.notifications where kind = 'challenge' order by created_at desc limit 1));
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
select t.expect_fail('other zone predicts', $q$insert into public.predictions (user_id, match_id, score_a, score_b) values (auth.uid(), t.ch(), 1, 0)$q$);
select t.check('other zone does not see challenge notification', (select count(*) = 0 from public.notifications where kind = 'challenge'));
select t.check('other zone does not see Badr team of the week', (select count(*) = 0 from public.team_of_week));
reset role;
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
insert into public.predictions (user_id, match_id, score_a, score_b) values (auth.uid(), t.ch(), 3, 1);
select t.check('own zone sees team of the week', (select count(*) = 1 from public.team_of_week));
reset role;
-- النتيجة من الأهداف: جولين لنسور بدر (الفريق الأول)
insert into public.events (match_id, player_id, type) select t.ch(), id, 'goal' from public.players where name in ('ه١', 'و١');
select t.check('score follows goals live', (select score_a = 2 and score_b = 0 and status = 'upcoming' from public.matches where id = t.ch()));
update public.matches set status = 'finished', score_a = 9, score_b = 9 where id = t.ch();   -- النتيجة اليدوي بتتجاهل
select t.check('manual score ignored', (select score_a = 2 and score_b = 0 from public.matches where id = t.ch()));
update public.matches set review_status = 'approved' where id = t.ch();   -- الاعتماد
select t.check('goal difference right (3-1 vs 2-0) = +5', public.fn_user_bonus('00000000-0000-0000-0000-000000000001') = 5);
select t.check('challenge summary counts goal difference', (select correct = 1 from public.challenge_summary(t.ch())));

-- ── حالة اللاعب: إشعار لمنطقته بس ──
update public.players set availability = 'injured', news = 'رباط صليبي' where name = 'ه١';
select t.check('status notification to player zone',
  (select audience = 'zone' from public.notifications where kind = 'status' and title like 'مصاب%'));
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
select t.check('other zone does not see who is injured', (select count(*) = 0 from public.notifications where title like 'مصاب%'));
reset role;

-- ── الكروت والتبديل ──
select t.check('yellow -1 · red -2', public.fn_score_points('MID', 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 1, 1) = -3);
insert into public.lineups (match_id, player_id, status) select t.ch(), id, 'bench' from public.players where name = 'ه٢'
  on conflict (match_id, player_id) do update set status = 'bench';
insert into public.lineups (match_id, player_id, status) select t.ch(), id, 'starting' from public.players where name = 'ه١'
  on conflict (match_id, player_id) do update set status = 'starting';
insert into public.events (match_id, player_id, other_player_id, type)
select t.ch(), (select id from public.players where name = 'ه٢'), (select id from public.players where name = 'ه١'), 'sub';
select t.check('sub recorded with 0 points', (select count(*) = 1 from public.events where type = 'sub'));
select t.expect_fail('sub across teams', $q$insert into public.events (match_id, player_id, other_player_id, type)
  select t.ch(), (select id from public.players where name = 'ه٢'), (select id from public.players where name = 'ه٣'), 'sub'$q$);
insert into public.events (match_id, player_id, type) select t.ch(), id, 'ownGoal' from public.players where name = 'و١';
select t.check('own goal adds to the other team', (select score_a = 2 and score_b = 1 from public.matches where id = t.ch()));

-- ── الإشعار بيفتح صفحته ──
select t.check('goal notification opens the match',
  (select bool_and(link = 'match:' || match_id) from public.notifications where kind = 'event'));
select t.check('challenge notification opens the challenge', (select bool_and(link = 'challenge') from public.notifications where kind = 'challenge'));
select t.check('player status opens the player', (select bool_and(link like 'player:%') from public.notifications where title like 'مصاب%'));
select t.check('confirm sheet opens the review', (select bool_and(link like 'review:%') from public.notifications where title like '📋%'));
select t.check('late match request opens admin screen', (select bool_and(link = 'admin:late') from public.notifications where title like '⏰%'));

-- ── حذف بالجملة · اللاعب عمل إيه ──
select t.check('player round matches: GK got his clean sheet match',
  (select count(*) >= 1 and bool_or(points > 0) from public.player_round_matches(
     (select id from public.players where name = 'ح١'), public.fn_week_cutoff(now()) - interval '7 days')));
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.expect_fail('user deletes players', $q$select public.delete_players(array(select id from public.players))$q$);
select t.expect_fail('user deletes accounts', $q$select public.admin_delete_users(array['00000000-0000-0000-0000-000000000002'::uuid])$q$);
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
select t.check('organizer cannot delete players who played', public.delete_players(array(select id from public.players where name = 'ه١')) = 0);
insert into public.players (name, team, position) values ('جديد', 'نسور بدر', 'DEF');
select t.check('organizer deletes own unused player', public.delete_players(array(select id from public.players where name = 'جديد')) = 1);
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select t.check('admin never deletes admins or himself',
  public.admin_delete_users(array['00000000-0000-0000-0000-00000000000a'::uuid]) = 0);
select t.check('admin deletes an account', public.admin_delete_users(array['00000000-0000-0000-0000-000000000004'::uuid]) = 1);
reset role;
select t.check('deleted account is gone', (select count(*) = 0 from public.profiles where id = '00000000-0000-0000-0000-000000000004'));

-- ── حذف لاعب طلع تبديل (كان بيكسر الحذف) + حذف الكل ──
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select t.check('admin deletes a subbed-out player', public.delete_players(array(select id from public.players where name = 'ه١')) = 1);
select t.check('admin deletes all players', public.delete_players(array(select id from public.players)) > 0);
reset role;
select t.check('no players left', (select count(*) = 0 from public.players));
