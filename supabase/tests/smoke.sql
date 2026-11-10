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

-- ميعاد ماتش جوه الجولة المفتوحة بعد ٣+k ساعات (وفي فاصل السبت: بعد بداية الجولة الجاية)
-- ملحوظة: السبت من ٥ لـ ٨ الصبح الجولة الحالية مفيهاش وقت لماتش جديد — الاختبار ده ممكن يقع لو اتشغّل ساعتها.
create function t.slot(k int) returns timestamptz language sql as $$
  select greatest(now(), public.fn_round_start(public.fn_open_round())) + (3 + k) * interval '1 hour';
$$;
grant execute on function t.slot(int) to anon, authenticated;

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
values (array['نسور بدر', 'صقور بدر'], t.slot(0), 1);
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
select t.check('others picks hidden before their players lock', (select count(*) = 0 from public.round_picks where user_id <> auth.uid()));
reset role;
select t.check('lineup saved (7)', (select count(*) = 7 from public.round_picks where user_id = '00000000-0000-0000-0000-000000000001'));
select t.as_user('00000000-0000-0000-0000-000000000003');
set role authenticated;
select t.expect_fail('pick from another zone', $q$select public.save_round_picks(public.fn_open_round(), t.lineup())$q$);
reset role;

-- ── الماتش يتلعب: ننقله للجولة الشغّالة (بصلاحيات السيرفر) ونسجّل أحداث ──
update public.matches set date_time = now() - interval '30 minutes';
insert into public.lineups (match_id, player_id, status)
select (select id from public.matches limit 1), id, 'starting' from public.players;
select t.check('lineup posted: appearance +3 per starter right away (5×3 + captain 3 = 18)',
  (select points = 18 from public.user_round_points
   where user_id = '00000000-0000-0000-0000-000000000001' and round_end = public.fn_week_cutoff(now())));
update public.lineups set status = 'bench' where player_id = (select id from public.players where name = 'و١');
select t.check('starter moved to bench: his appearance points go (15)',
  (select points = 15 from public.user_round_points
   where user_id = '00000000-0000-0000-0000-000000000001' and round_end = public.fn_week_cutoff(now())));
update public.lineups set status = 'starting' where player_id = (select id from public.players where name = 'و١');
update public.players set user_id = '00000000-0000-0000-0000-000000000001' where name = 'د١';
update public.players set user_id = '00000000-0000-0000-0000-000000000002' where name = 'د٢';
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into public.events (match_id, player_id, type, minute)
select (select id from public.matches limit 1), id, 'goal', 10 from public.players where name = 'ه١';
reset role;
select t.check('captain goal (5+3)×2 + 4 starters ×3 = 28 live points',
  (select points = 28 and final_points = 0 from public.user_round_points
   where user_id = '00000000-0000-0000-0000-000000000001' and round_end = public.fn_week_cutoff(now())));
select t.check('total not counted before approval', (select total_points = 0 from public.profiles where id = '00000000-0000-0000-0000-000000000001'));

-- ── المدير يقفل الماتش → تأكيد الفريقين → اعتماد ──
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
update public.matches set status = 'finished', score_a = 1, score_b = 0;
reset role;
select t.check('match pending review', (select review_status = 'pending' from public.matches limit 1));
select t.check('new organizer flagged', (select 'new_organizer' = any(flags) from public.matches limit 1));

-- ── الماتش خلص: المنظّم ميقدرش يعدّل حاجة ──
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
select t.expect_fail('organizer adds event after finish',
  $q$insert into public.events (match_id, player_id, type, minute)
     select (select id from public.matches limit 1), id, 'goal', 20 from public.players where name = 'ه١'$q$);
update public.matches set score_a = 5;
select t.check('organizer cannot edit finished match', (select score_a = 1 from public.matches limit 1));

-- ── هدف وتصدّي الجولة: المدير يرشّح من ماتشه اللي خلص ──
select t.check('organizer nominates a goal', public.nominate_award('goal', (select id from public.matches limit 1),
  (select id from public.players where name = 'ه١'), 'https://youtu.be/abc123') is not null);
select t.expect_fail('same nomination twice', $q$select public.nominate_award('goal', (select id from public.matches limit 1),
  (select id from public.players where name = 'ه١'), 'https://youtu.be/abc123')$q$);
select t.expect_fail('nomination needs a video link', $q$select public.nominate_award('save', (select id from public.matches limit 1),
  (select id from public.players where name = 'ه١'), 'not a link')$q$);
select t.check('my nominations listed', (select count(*) = 1 from public.my_award_nominations()));
reset role;
select t.check('zone goal poll opened + notified',
  (select count(*) = 1 from public.polls where kind = 'goal_week' and zone_id is not null)
  and (select count(*) = 1 from public.notifications where kind = 'vote' and audience = 'zone'));
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select t.expect_fail('user cannot nominate', $q$select public.nominate_award('goal', (select id from public.matches limit 1),
  (select id from public.players where name = 'ه١'), 'https://youtu.be/x')$q$);

-- ── بلاغ مراهنات → الأدمنز بيوصلهم إشعار ──
select t.check('user reports betting', public.report_betting('مدير بدر', 'بيعمل رهان على نقط الدوري بفلوس') is not null);
select t.expect_fail('user cannot list reports', $q$select * from public.admin_betting_reports()$q$);
reset role;
select t.check('admins notified of betting report',
  (select count(*) >= 1 from public.notifications where link = 'admin:betting'));
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select t.check('report on a specific account', public.report_betting('يوزر٣', 'بيلم فلوس على نتيجة التحدي كل جولة',
  '00000000-0000-0000-0000-000000000003') is not null);
select t.expect_fail('cannot report yourself', $q$select public.report_betting('أنا', 'بلاغ على نفسي للتجربة',
  '00000000-0000-0000-0000-000000000002')$q$);
select t.expect_fail('user cannot resolve reports',
  $q$select public.resolve_betting_report((select id from public.betting_reports limit 1), 'proven')$q$);
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select t.check('admin sees betting reports', (select count(*) = 2 from public.admin_betting_reports()));
select t.check('proven on an account = permanent ban', public.resolve_betting_report(
  (select id from public.betting_reports where suspect_user is not null limit 1), 'proven'));
select t.check('proven on a name only = no auto ban', not public.resolve_betting_report(
  (select id from public.betting_reports where suspect_user is null limit 1), 'proven'));
reset role;
select t.check('reported account is banned',
  (select not is_active from public.profiles where id = '00000000-0000-0000-0000-000000000003'));
update public.profiles set is_active = true where id = '00000000-0000-0000-0000-000000000003';
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select public.review_match((select id from public.matches limit 1), true, null);
reset role;
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select public.review_match((select id from public.matches limit 1), true, null);
reset role;
select t.check('both teams confirmed → approved', (select review_status = 'approved' from public.matches limit 1));
select t.check('points counted after approval (+ GK clean sheet)', (select total_points = 36 from public.profiles where id = '00000000-0000-0000-0000-000000000001'));

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
select t.check('4 goals FWD = 28 raw → capped 25', public.fn_score_points('FWD', 4, 0, 0, 0, 0, 0, 0, 0, 0, false) = 25);
select t.check('GK goal = 8', public.fn_score_points('GK', 1, 0, 0, 0, 0, 0, 0, 0, 0, false) = 8);
select t.check('4 assists = 3×3 + 5 + bonus 4 = 18', public.fn_score_points('MID', 0, 4, 0, 0, 0, 0, 0, 0, 0, false) = 18);
select t.check('7 saves = 2 · 10 tackles = 2', public.fn_score_points('GK', 0, 0, 7, 0, 0, 10, 0, 0, 0, false) = 4);
select t.check('starter appearance = 3', public.fn_score_points('FWD', 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, true) = 3);
select t.check('penalty save 4 · clean sheet 8', public.fn_score_points('GK', 0, 0, 0, 1, 0, 0, 0, 0, 0, true) = 12);
select t.check('penalty miss -3 · insult -5 · own goal -2 · motm +3',
  public.fn_score_points('DEF', 0, 0, 0, 0, 1, 0, 1, 1, 1, false) = -7);

-- ── ديدلاين لكل لاعب + تغيير واحد ببلاش ──
-- ماتش نسور/صقور يرجع «بدأ من نص ساعة» جوه الجولة الحالية (وبيرجع مكانه في الآخر)
create temp table _wk1 as select id, date_time from public.matches where week = 1;
update public.matches set date_time = now() - interval '30 minutes' where week = 1;
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000005', 'u5@t.co', jsonb_build_object('name', 'يوزر٥', 'phone', '0106', 'zone_id', (select id from public.zones where name = 'بدر')));
-- فريق تالت ملوش ماتشات (لاعيبته مش متقفلين) — ماتش نسور/صقور بدأ من نص ساعة (لاعيبته متقفلين)
insert into public.teams (name, owner_id) values ('نمور بدر', '00000000-0000-0000-0000-00000000000b');
insert into public.players (name, team, position, zone_id)
select n, 'نمور بدر', pos, (select id from public.zones where name = 'بدر')
from (values ('ح٣', 'GK'), ('د٣', 'FWD'), ('و٣', 'FWD'), ('ه٥', 'FWD'), ('ه٦', 'FWD'), ('ه٧', 'FWD'), ('ه٨', 'FWD'), ('ه٩', 'FWD'), ('ه١٠', 'FWD')) v(n, pos);
create function t.tigers(bench2 text) returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('player_id', id, 'status', case when name in ('ه٧', bench2) then 'bench' else 'starting' end,
                                      'is_captain', name = 'ه٥', 'is_vice', name = 'ه٦'))
  from public.players where name in ('ح٣', 'د٣', 'و٣', 'ه٥', 'ه٦', 'ه٧', bench2);
$$;
grant execute on function t.tigers(text) to authenticated;
-- تشكيلة يوزر٥ في الجولة اللي فاتت (هي اللي بنعدّ التغييرات منها)
insert into public.round_picks (user_id, round_end, player_id, status, is_captain, is_vice)
select '00000000-0000-0000-0000-000000000005', public.fn_open_round() - interval '7 days', (e->>'player_id')::uuid,
       e->>'status', (e->>'is_captain')::boolean, (e->>'is_vice')::boolean
from jsonb_array_elements(t.tigers('ه٨')) e;
select t.as_user('00000000-0000-0000-0000-000000000005');
set role authenticated;
select public.save_round_picks(public.fn_open_round(), t.tigers('ه٨'));
select t.check('same lineup as last round = 0 transfers', (public.my_round_state(public.fn_open_round())->>'transfers')::int = 0);
select public.save_round_picks(public.fn_open_round(), t.tigers('ه٩'));
select t.check('1 change = the free transfer', (public.my_round_state(public.fn_open_round())->>'transfers')::int = 1);
select t.check('baseline = last round lineup', jsonb_array_length(public.my_round_state(public.fn_open_round())->'baseline') = 7);
select t.check('locks: players of the started match are listed',
  (public.my_round_state(public.fn_open_round())->'locks') ? (select id::text from public.players where name = 'ح١'));
select t.expect_fail('adding a player whose match started', $q$select public.save_round_picks(public.fn_open_round(),
  (select jsonb_agg(case when e->>'player_id' = (select id::text from public.players where name = 'ه٩')
     then jsonb_set(e, '{player_id}', to_jsonb((select id from public.players where name = 'ه١'))) else e end)
   from jsonb_array_elements(t.tigers('ه٩')) e))$q$);
select t.check('others see a player only after he locks',
  (select count(*) = 7 from public.round_picks where user_id = '00000000-0000-0000-0000-000000000001' and round_end = public.fn_open_round()));
reset role;
-- تغيير تاني = −٤ (الفريق ده ملعبش، فالنقط = −٤ بالظبط)
select t.as_user('00000000-0000-0000-0000-000000000005');
set role authenticated;
select public.save_round_picks(public.fn_open_round(), (select jsonb_agg(case when e->>'player_id' = (select id::text from public.players where name = 'د٣')
  then jsonb_set(e, '{player_id}', to_jsonb((select id from public.players where name = 'ه١٠'))) else e end)
  from jsonb_array_elements(t.tigers('ه٩')) e));
reset role;
select t.check('2 changes: 1 free + 1 × −4', (select transfers = 2 from public.round_transfers
  where user_id = '00000000-0000-0000-0000-000000000005' and round_end = public.fn_open_round())
  and (select points = -4 from public.user_round_points where user_id = '00000000-0000-0000-0000-000000000005'
       and round_end = public.fn_open_round()));
select t.check('transfer cost rule', public.fn_transfer_cost(0, false, 1) = 0 and public.fn_transfer_cost(1, false, 1) = 0
  and public.fn_transfer_cost(3, false, 1) = 8 and public.fn_transfer_cost(5, true, 1) = 0 and public.fn_transfer_cost(3, false, 3) = 0);
-- المجاني بيتجمّع: جولة من غير تغييرات = ٢ الجولة الجاية · آخره ٥ · الوايلد كارد مبياكلش منه
insert into public.round_transfers (user_id, round_end, transfers, free) values
  ('00000000-0000-0000-0000-000000000005', timestamptz '2030-01-05 06:00+00', 0, 1),
  ('00000000-0000-0000-0000-000000000005', timestamptz '2030-01-12 06:00+00', 1, 4),
  ('00000000-0000-0000-0000-000000000005', timestamptz '2030-01-19 06:00+00', 0, 5);
select t.check('free transfers bank: unused 1 → 2 next round',
  public.fn_free_for('00000000-0000-0000-0000-000000000005', timestamptz '2030-01-12 06:00+00') = 2);
select t.check('free transfers bank: 4 − 1 used + 1 = 4',
  public.fn_free_for('00000000-0000-0000-0000-000000000005', timestamptz '2030-01-19 06:00+00') = 4);
select t.check('free transfers capped at 5',
  public.fn_free_for('00000000-0000-0000-0000-000000000005', timestamptz '2030-01-26 06:00+00') = 5);
select t.check('no earlier round = 1 free',
  public.fn_free_for('00000000-0000-0000-0000-000000000005', timestamptz '2029-01-01 06:00+00') = 1);
delete from public.round_transfers where user_id = '00000000-0000-0000-0000-000000000005' and round_end > timestamptz '2029-01-01';
-- يوزر١: كل لاعيبته اتقفلوا
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.expect_fail('moving the captain away from a locked player', $q$select public.save_round_picks(public.fn_open_round(),
  (select jsonb_agg(jsonb_set(jsonb_set(e, '{is_captain}', to_jsonb(e->>'player_id' = (select id::text from public.players where name = 'و١'))),
     '{is_vice}', to_jsonb(e->>'player_id' = (select id::text from public.players where name = 'ه١'))))
   from jsonb_array_elements(t.lineup()) e))$q$);
reset role;
select t.check('chips: every chip (wildcard too) blocked once a player in the lineup locks',
  public.fn_chip_blocked('00000000-0000-0000-0000-000000000001', public.fn_open_round(), 'triple') is not null
  and public.fn_chip_blocked('00000000-0000-0000-0000-000000000001', public.fn_open_round(), 'wildcard') is not null
  and public.fn_chip_blocked('00000000-0000-0000-0000-000000000005', public.fn_open_round(), 'triple') is null);
-- أول الجولة: التشكيلة بتتنقل لوحدها · وقبل الماتش بساعتين إشعار القفل
delete from public.round_picks where user_id = '00000000-0000-0000-0000-000000000005' and round_end = public.fn_open_round();
delete from public.round_transfers where user_id = '00000000-0000-0000-0000-000000000005' and round_end = public.fn_open_round();
delete from public.app_jobs where key like 'carry:%';
insert into public.matches (teams, date_time, created_at, zone_id, week)
values (array['نمور بدر', 'صقور بدر'], now() + interval '90 minutes', now() - interval '2 days', (select id from public.zones where name = 'بدر'), 8);
select public.fn_round_tick();
select t.check('round start: last lineup carried over', (select count(*) = 7 from public.round_picks
  where user_id = '00000000-0000-0000-0000-000000000005' and round_end = public.fn_open_round()));
select t.check('round start: the new round opens with the banked free transfers',
  (select free >= 1 and transfers = 0 from public.round_transfers
   where user_id = '00000000-0000-0000-0000-000000000005' and round_end = public.fn_open_round()));
select t.check('2 hours before: zone told its players lock in an hour (deadline sound)',
  (select count(*) = 1 from public.notifications where title like '⏳%' and sound = 'deadline' and audience = 'zone'));
select public.fn_round_tick();
select t.check('lock reminder sent once', (select count(*) = 1 from public.notifications where title like '⏳%'));
delete from public.matches where week = 8;
update public.matches m set date_time = w.date_time from _wk1 w where w.id = m.id;

-- ── مفيش ديدلاين للجولة: أي ماتش قبل ميعاده بساعتين بيدخل على طول + إشعار لأهل المنطقة ──
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
select t.expect_fail('late requests are gone', $q$select public.request_late_match(array['نسور بدر', 'صقور بدر'], now() + interval '1 day')$q$);
select t.expect_fail('organizer: match less than 2 hours ahead',
  $q$insert into public.matches (teams, date_time) values (array['نسور بدر', 'صقور بدر'], now() + interval '90 minutes')$q$);
insert into public.matches (teams, date_time, week) values (array['نسور بدر', 'صقور بدر'], t.slot(2), 7);
reset role;
select t.check('match added mid-round without approval', (select count(*) = 1 from public.matches where week = 7));
select t.check('zone notified: new match, you can pick its players',
  (select count(*) = 1 from public.notifications where title like 'ماتش جديد في منطقتك%' and audience = 'zone'
     and match_id = (select id from public.matches where week = 7)));
delete from public.matches where week = 7;
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
insert into public.matches (teams, date_time) values (array['أ', 'ب'], public.fn_week_cutoff(now()) - interval '2 minutes');
reset role;
select t.check('admin adds a match any time', (select count(*) = 1 from public.matches where teams = array['أ', 'ب']));

-- ── مواعيد الجولة: [السبت ٤ العصر , السبت اللي بعده ٨ الصبح] · الديدلاين السبت ١٢ الضهر ──
create function t.cairo(x text) returns timestamptz language sql as $$ select x::timestamp at time zone 'Africa/Cairo' $$;
select t.check('Fri night match ends round at Sat 08:00', public.fn_week_cutoff(t.cairo('2026-10-03 07:59')) = t.cairo('2026-10-03 08:00'));
select t.check('Sat 16:00 match is next round', public.fn_week_cutoff(t.cairo('2026-10-03 16:00')) = t.cairo('2026-10-10 08:00'));
select t.check('round start Sat 16:00', public.fn_round_start(t.cairo('2026-10-10 08:00')) = t.cairo('2026-10-03 16:00'));
select t.check('round "deadline" = its start (Sat 16:00) — real locks are per player', public.fn_round_deadline(t.cairo('2026-10-10 08:00')) = t.cairo('2026-10-03 16:00'));
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
insert into public.matches (teams, date_time, week) values (array['نسور بدر', 'صقور بدر'], t.slot(1), 2);
insert into public.matches (teams, date_time, week) values (array['صقور بدر', 'نسور بدر'], t.slot(2), 2);
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
select t.expect_fail('duel needs a player from each team', $q$select public.set_challenge(t.ch(), array['duel'],
  (select id from public.players where name = 'ه١'), (select id from public.players where name = 'و١'))$q$);
select t.expect_fail('challenge needs a known mode', $q$select public.set_challenge(t.ch(), array['nope'])$q$);
select public.set_challenge(t.ch(), array['diff', 'duel', 'quiz', 'lowest'],
  (select id from public.players where name = 'ه١'),
  (select id from public.players where team = 'صقور بدر' order by name limit 1));
update public.matches set challenge_modes = '{}' where id = t.ch();
select t.check('organizer cannot edit challenge modes directly',
  (select cardinality(challenge_modes) = 4 from public.matches where id = t.ch()));
select t.expect_fail('second challenge same round same organizer',
  $q$select public.set_challenge((select id from public.matches where week = 2 order by date_time desc limit 1))$q$);
reset role;
select t.check('challenge notification to the zone only',
  (select audience = 'zone' and zone_id = (select id from public.zones where name = 'بدر')
   from public.notifications where kind = 'challenge' order by created_at desc limit 1));
select t.as_user('00000000-0000-0000-0000-000000000004');
set role authenticated;
select t.expect_fail('other zone predicts', $q$insert into public.predictions (user_id, match_id, score_a, score_b) values (auth.uid(), t.ch(), 1, 0)$q$);
select t.expect_fail('other zone answers challenge', $q$select public.answer_challenge(t.ch(), null, 'a', false)$q$);
select t.check('other zone does not see challenge notification', (select count(*) = 0 from public.notifications where kind = 'challenge'));
select t.check('other zone does not see Badr team of the week', (select count(*) = 0 from public.team_of_week));
reset role;
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
insert into public.predictions (user_id, match_id, score_a, score_b) values (auth.uid(), t.ch(), 3, 1);
select t.expect_fail('duel pick must be one of the two', $q$select public.answer_challenge(t.ch(),
  (select id from public.players where name = 'و١'))$q$);
select public.answer_challenge(t.ch(), (select id from public.players where name = 'ه١'), 'a', false,
  (select id from public.players where name = 'ه١'), null);
select t.check('challenge board lists my answers',
  (select jsonb_array_length(b->'items') >= 1 and (b->'items'->0->'mine'->>'q_winner') = 'a' from public.challenge_board() b));
select t.check('own zone sees team of the week', (select count(*) = 1 from public.team_of_week));
reset role;
-- النتيجة من الأهداف: جولين لنسور بدر (الفريق الأول)
insert into public.events (match_id, player_id, type) select t.ch(), id, 'goal' from public.players where name in ('ه١', 'و١');
select t.check('score follows goals live', (select score_a = 2 and score_b = 0 and status = 'upcoming' from public.matches where id = t.ch()));
update public.matches set status = 'finished', score_a = 9, score_b = 9 where id = t.ch();   -- النتيجة اليدوي بتتجاهل
select t.check('manual score ignored', (select score_a = 2 and score_b = 0 from public.matches where id = t.ch()));
update public.matches set review_status = 'approved' where id = t.ch();   -- الاعتماد
-- فرق الأهداف +٥ · مين فيهم +٣ · الأسئلة: الفايز +٢ والأهداف +٢ (وأول هدّاف لو صح يبقوا التلاتة = +١٠)
select t.check('challenge: diff 5 + duel 3 + quiz (4 or 10)',
  public.fn_user_bonus('00000000-0000-0000-0000-000000000001') in (12, 18));
select t.check('challenge scores per mode',
  (select diff_pts = 5 and streak = 1 and duel_pts = 3 and quiz_pts in (4, 10) and lowest_pts = 0
   from public.fn_challenge_scores('00000000-0000-0000-0000-000000000001') where match_id = t.ch()));
select t.check('challenge win notification', (select count(*) = 1 from public.notifications where title like '🎯 كسبت +%'));
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

-- ── كارت الرئيسية + نقط اللاعب في كل جولة (كانت بتقع بالصلاحيات) ──
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select t.check('player_history runs as a user', (select count(*) >= 0 from public.player_history((select id from public.players where name = 'ه١'))));
select t.check('round_highlights returns one row', (select count(*) = 1 from public.round_highlights(now())));
reset role;

-- ── الإيميل مبيطلعش من رقم الموبايل (للسيرفر بس) + عدّاد المحاولات ──
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select t.expect_fail('user cannot map phone to email', $q$select public.email_for_phone('0101')$q$);
select t.expect_fail('user cannot call phone_auth_email', $q$select public.phone_auth_email('0101', 10)$q$);
reset role;
set role anon;
select t.expect_fail('anon cannot map phone to email', $q$select public.email_for_phone('0101')$q$);
reset role;
select t.check('server resolves the phone', public.phone_auth_email('010100', 3) is null);
select public.phone_auth_email('010100', 3);
select public.phone_auth_email('010100', 3);
select t.expect_fail('phone attempts are throttled', $q$select public.phone_auth_email('010100', 3)$q$);

-- ── الدوري العام بيتصفّر مع الموسم ──
create temp table _tot as select total_points as v from public.profiles where id = '00000000-0000-0000-0000-000000000001';
select t.check('user has points before seasons', (select v > 0 from _tot));
delete from public.seasons;
insert into public.seasons (name, starts_at, mid_at, ends_at)
values ('الموسم الحالي', now() - interval '60 days', now(), now() + interval '60 days');
select t.check('current season covers the points: total unchanged',
  (select total_points = (select v from _tot) from public.profiles where id = '00000000-0000-0000-0000-000000000001'));
update public.seasons set starts_at = now() - interval '90 days', mid_at = now() - interval '80 days', ends_at = now() - interval '70 days';
select t.check('points outside the season do not count (league reset)',
  (select total_points = 0 from public.profiles where id = '00000000-0000-0000-0000-000000000001'));
delete from public.seasons;
select t.check('no seasons: all-time total is back',
  (select total_points = (select v from _tot) from public.profiles where id = '00000000-0000-0000-0000-000000000001'));

-- ── التحديث الإجباري + مدة الماتش ──
set role anon;
select t.check('anyone reads app config', (select (public.get_app_config()->>'min_build_android') = '0'));
select t.expect_fail('anon cannot set min build', $q$select public.set_app_config('min_build_android', '5')$q$);
reset role;
select t.as_user('00000000-0000-0000-0000-000000000002');
set role authenticated;
select t.expect_fail('user cannot set min build', $q$select public.set_app_config('min_build_android', '5')$q$);
select t.expect_fail('user cannot extend a match', $q$select public.extend_match((select id from public.matches limit 1), 15)$q$);
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select public.set_app_config('min_build_android', '7');
select t.expect_fail('min build must be a number', $q$select public.set_app_config('min_build_android', 'abc')$q$);
reset role;
select t.check('admin set the minimum build', (select (public.get_app_config()->>'min_build_android') = '7'));
-- ماتش بدأ من ٥٥ دقيقة ومدته ساعة: تنبيه للمدير، وبعد ما المدة تخلص بيتقفل لوحده
-- (الميعاد نسبة لدلوقتي — فالاختبار ده ممكن يقع لو اتشغّل السبت ٩ الصبح–٥ العصر: الفاصل بين الجولتين)
create temp table _dm (id uuid);
with ins as (
  insert into public.matches (teams, date_time, organizer_id, zone_id)
  values (array['نسور بدر', 'صقور بدر'], now() - interval '55 minutes', '00000000-0000-0000-0000-00000000000b',
          (select id from public.zones where name = 'بدر'))
  returning id)
insert into _dm select id from ins;
grant select on _dm to authenticated;
insert into public.lineups (match_id, player_id, status)
select (select id from _dm), id, 'starting' from public.players limit 2;
select public.fn_close_due_matches();
select t.check('organizer warned 10 minutes before the end',
  (select count(*) = 1 from public.notifications where title like '⏱%' and match_id = (select id from _dm))
  and (select status = 'upcoming' and end_warned from public.matches where id = (select id from _dm)));
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
select t.check('organizer extends by 15 minutes', public.extend_match((select id from _dm), 15) = 75);
reset role;
update public.matches set date_time = now() - interval '80 minutes' where id = (select id from _dm);
select public.fn_close_due_matches();
select t.check('match auto-finished when its time is up',
  (select status = 'finished' from public.matches where id = (select id from _dm)));

-- ── يوزر عادي يعمل دوري (خاص وعام) ويبقى عضو فيه ──
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
create temp table _lg as
with ins as (insert into public.leagues (name, type, invite_code, owner_id)
             values ('دوري صحابي', 'private', 'TESTC1', auth.uid()) returning id)
select id from ins;
insert into public.league_members (league_id, user_id) select id, auth.uid() from _lg;
select t.check('user created a private league and joined it',
  (select count(*) = 1 from public.league_members where league_id = (select id from _lg)));
select t.check('owner sees his league standings', (select count(*) = 1 from public.league_standings((select id from _lg))));
reset role;

-- ── نغمة كل إشعار ──
select t.check('goal notifications use the goal sound',
  (select bool_and(sound = 'goal') from public.notifications where kind = 'event' and title like 'جوووول%'));
select t.check('other match events use the general sound',
  (select coalesce(bool_and(sound = 'general'), true) from public.notifications
   where kind = 'event' and title not like 'جوووول%' and title not like 'جول عكسي%'));
select t.check('match finished uses the match sound',
  (select bool_and(sound = 'match') from public.notifications where title like 'انتهى الماتش%'));
select t.check('lineup notifications use the lineup sound',
  (select coalesce(bool_and(sound = 'lineup'), true) from public.notifications where kind = 'lineup'));
select t.check('every notification has a sound', (select count(*) = 0 from public.notifications where sound is null));
select public.fn_round_tick();
select public.fn_match_start_tick();
select public.fn_close_due_matches_and_season();

-- ── حذف لاعب طلع تبديل (كان بيكسر الحذف) + حذف الكل ──
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select t.check('admin deletes a subbed-out player', public.delete_players(array(select id from public.players where name = 'ه١')) = 1);
select t.check('admin deletes all players', public.delete_players(array(select id from public.players)) > 0);
reset role;
select t.check('no players left', (select count(*) = 0 from public.players));

-- ══ السنة بدل الموسم ══
select t.check('this year and next exist automatically', (select count(*) >= 2 from public.seasons
  where year in (extract(year from now() at time zone 'Africa/Cairo')::int, extract(year from now() at time zone 'Africa/Cairo')::int + 1)));
select t.check('a year runs Jan 1 → Jan 1 (Cairo), half = Jul 1', (select starts_at = t.cairo('2027-01-01 00:00')
  and mid_at = t.cairo('2027-07-01 00:00') and ends_at = t.cairo('2028-01-01 00:00') from public.seasons where year = 2027));
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select t.expect_fail('admin cannot create seasons by hand',
  $q$insert into public.seasons (name, starts_at, mid_at, ends_at) values ('x', now(), now() + interval '1 day', now() + interval '2 days')$q$);
reset role;

select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select public.send_my_test_push();
select t.expect_fail('test push rate limit (1 per minute)', $q$select public.send_my_test_push()$q$);
reset role;
select t.check('test push goes to me only, with the goal sound', (select count(*) = 1 from public.notifications
  where title = '🔔 تجربة الإشعارات' and user_id = '00000000-0000-0000-0000-000000000001' and audience = 'user' and sound = 'goal'));

-- ══ تشكيلة الجولة لايف: من الماتشات المعتمدة بس + اعتماد تلقائي بعد ٤ ساعات ══
select t.check('auto-approval window = 4 hours', public.fn_review_window() = interval '4 hours');
select t.check('live TOTW counts approved matches only',
  (select coalesce(sum(points), 0) from public.player_points_approved('-infinity', 'infinity'))
  = (select coalesce(sum(x.points), 0) from public.fn_pmp('-infinity', 'infinity') x
     join public.matches m on m.id = x.match_id and m.review_status = 'approved'));

-- ══ فحص الحماية الشامل (بيفشل لو أي قسم جديد ساب حاجة مفتوحة) ══
reset role;
select t.check('every public table has RLS', (select count(*) = 0 from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity));
select t.check('every security definer function pins search_path', (select count(*) = 0 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prosecdef and not exists (select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search_path=%')));
select t.check('anon can call only get_app_config + log_events + phone_taken',
  (select array_agg(p.proname::text order by p.proname) = array['get_app_config', 'log_events', 'phone_taken'] from pg_proc p
   join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')));
select t.check('internal definer functions are server-only',
  (select count(*) = 13 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prosecdef and p.proname ~ '^(fn|trg)_' and has_function_privilege('authenticated', p.oid, 'execute')));
select t.check('anon has table rights on zones only (select)',
  (select count(*) = 1 and bool_and(table_name = 'zones' and privilege_type = 'SELECT')
   from information_schema.role_table_grants where table_schema = 'public' and grantee = 'anon'));
select t.check('anon policies: zones read + public photo buckets only',
  (select count(*) = 4 and bool_and(cmd = 'SELECT') from pg_policies where 'anon' = any(roles) or 'public' = any(roles)));

select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.expect_fail('user recalcs everyone', $q$select public.fn_recalc_all_totals()$q$);
select t.expect_fail('user snapshots ranks', $q$select public.fn_snapshot_ranks()$q$);
select t.expect_fail('user runs the match tick', $q$select public.fn_close_due_matches_and_season()$q$);
select t.expect_fail('user reads another user challenge scores', $q$select * from public.fn_challenge_scores('00000000-0000-0000-0000-000000000002')$q$);
select t.expect_fail('user sets app config (force update)', $q$select public.set_app_config('min_build', '999')$q$);
select t.expect_fail('user sets push url', $q$select public.set_push_url('https://evil.example')$q$);
select t.expect_fail('user deletes users', $q$select public.admin_delete_users(array['00000000-0000-0000-0000-000000000002'::uuid])$q$);
select t.expect_fail('user makes himself manager', $q$select public.set_user_role(auth.uid(), 'manager')$q$);
select t.expect_fail('user bans someone', $q$select public.set_user_active('00000000-0000-0000-0000-000000000002', false)$q$);
select t.expect_fail('user resolves betting report', $q$select public.resolve_betting_report(gen_random_uuid(), 'banned')$q$);
select t.expect_fail('user reads phone→email', $q$select public.phone_auth_email('0102', 5)$q$);
select t.expect_fail('user writes app_config', $q$insert into public.app_config (key, value) values ('x', 'y')$q$);
select t.expect_fail('user inserts a notification', $q$insert into public.notifications (title, body, kind, audience) values ('x', 'y', 'event', 'all')$q$);
select t.expect_fail('user writes team of the week', $q$insert into public.team_of_week (round_end, zone_id, players) values (now(), 0, '[]')$q$);
select t.expect_fail('user creates a season', $q$insert into public.seasons (name, starts_at, mid_at, ends_at) values ('x', now(), now(), now())$q$);
select t.expect_fail('user reads phones directly', $q$select phone from public.profiles$q$);
select t.expect_fail('user reads emails directly', $q$select email from public.profiles$q$);
reset role;
set role anon;
select t.expect_fail('anon reads profiles', $q$select 1 / (select count(*) from public.profiles)$q$);
select t.expect_fail('anon reads matches', $q$select 1 / (select count(*) from public.matches)$q$);
select t.expect_fail('anon calls an app rpc', $q$select public.my_profile()$q$);
reset role;

-- ══ السجلات (logs) ══
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.check('log_events stores valid events only (bad level / bad event name dropped)', public.log_events('[
  {"timestamp":"2026-10-13T15:27:04.118Z","level":"error","event":"http.error","env":"prod","version":"1.0.0+1",
   "request_id":"req_test_1","route":"POST /rest/v1/rpc/save_round_picks","status":500,"duration_ms":1234,
   "error_type":"PostgrestException","message":"failed for a.user@gmail.com 01012345678",
   "fields":{"password":"hunter2","access_token":"abc","code":"123456","screen":"pick","email":"someone@mail.com"}},
  {"level":"shout","event":"x.y"},
  {"level":"info","event":"Bad Name!"}]'::jsonb) = 1);
select t.expect_fail('user reads logs directly', $q$select 1 / (select count(*) from public.app_logs)$q$);
select t.expect_fail('user reads logs via admin rpc', $q$select * from public.admin_logs()$q$);
select t.expect_fail('user reads log stats', $q$select public.admin_log_stats()$q$);
select t.expect_fail('user calls the internal logger', $q$select public.fn_log('error', 'fake.event')$q$);
select t.expect_fail('user sets log level', $q$select public.set_app_config('log_level', 'debug')$q$);
reset role;
select t.check('log row: server-side user id, secrets dropped, email/phone masked',
  (select user_id = '00000000-0000-0000-0000-000000000001' and not (fields ?| array['password', 'access_token', 'code'])
          and fields->>'screen' = 'pick' and fields->>'email' = 's***@mail.com'
          and message not like '%a.user@gmail.com%' and message not like '%01012345678%'
          and status = 500 and duration_ms = 1234 and client_ts is not null
   from public.app_logs where request_id = 'req_test_1'));
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select public.log_events((select jsonb_agg(jsonb_build_object('level', 'error', 'event', 'flood.test', 'error_type', 'FloodError')) from generate_series(1, 20)))
from generate_series(1, 5);
reset role;
select t.check('log rate limit: 60 per user per 5 minutes',
  (select count(*) = 60 from public.app_logs where user_id = '00000000-0000-0000-0000-000000000001' and service = 'app'));
select set_config('request.jwt.claim.sub', '', false);
set role anon;
select t.check('anon can report an error (no user id)', public.log_events('[{"level":"error","event":"auth.signup.failed"}]'::jsonb) = 1);
reset role;
select public.fn_log_watch();
select t.check('error spike + new error → admin alerted once (link admin:logs)',
  (select count(*) = 2 from public.notifications where link = 'admin:logs' and user_id = '00000000-0000-0000-0000-00000000000a'));
select public.fn_log_watch();
select t.check('alerts are throttled (no duplicates within 30 minutes)',
  (select count(*) = 2 from public.notifications where link = 'admin:logs' and user_id = '00000000-0000-0000-0000-00000000000a'));
update public.app_logs set ts = now() - interval '40 days' where event = 'flood.test';
select public.fn_log_watch();
select t.check('retention: logs older than 30 days are purged', (select count(*) = 0 from public.app_logs where event = 'flood.test'));
select t.as_user('00000000-0000-0000-0000-00000000000a');
set role authenticated;
select t.check('admin searches logs by request id', (select count(*) = 1 from public.admin_logs(null, 'req_test_1')));
select t.check('admin log stats', (select (public.admin_log_stats()->>'errors_24h')::int >= 1));
select public.set_app_config('log_level', 'debug');
select t.expect_fail('bad log level rejected', $q$select public.set_app_config('log_level', 'loud')$q$);
reset role;
select t.check('admin action mirrored to the central log as an audit event',
  (select count(*) >= 1 from public.app_logs where event = 'audit.admin.app_config' and service = 'db'
     and user_id = '00000000-0000-0000-0000-00000000000a'));
