-- وضع التجربة: ماتش دلوقتي حالًا → تشكيلة للجولة الشغّالة → النتيجة → اعتماد بعد ١٠ دقايق
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
update public.profiles set role = 'organizer' where id = '00000000-0000-0000-0000-00000000000b';
select t.check('test mode on', public.fn_test_mode());
select t.check('open round = the current one', public.fn_open_round() = public.fn_week_cutoff(now()));
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into public.teams (name) values ('أ'), ('ب');
insert into public.players (name, team, position) values
 ('ح', 'أ', 'GK'), ('د', 'أ', 'DEF'), ('و', 'أ', 'MID'), ('ه', 'أ', 'FWD'), ('ه٢', 'أ', 'FWD'), ('د٢', 'ب', 'DEF'), ('ه٣', 'ب', 'FWD');
insert into public.matches (teams, date_time, week) values (array['أ', 'ب'], now() + interval '2 minutes', 1);
reset role;
select t.check('match notification sent to the zone', (select count(*) = 1 from public.notifications where title like 'ماتش جديد%'));
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select public.save_round_picks(public.fn_open_round(), (select jsonb_agg(jsonb_build_object('player_id', id,
  'status', case when name in ('ه٢', 'ه٣') then 'bench' else 'starting' end, 'is_captain', name = 'ه', 'is_vice', name = 'و'))
  from public.players));
reset role;
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into public.lineups (match_id, player_id, status) select (select id from public.matches), id, 'starting' from public.players;
insert into public.events (match_id, player_id, type) select (select id from public.matches), id, 'goal' from public.players where name = 'ه';
update public.matches set status = 'finished', score_a = 1, score_b = 0;
reset role;
select t.check('review due in 10 minutes', (select review_due < now() + interval '11 minutes' from public.matches));
select t.check('live round points: captain goal 10 + GK clean sheet 8', (select points = 18 from public.user_round_points where user_id = '00000000-0000-0000-0000-000000000001'));

-- ── جولة واحدة في التجربة: ماتش بعد أسبوعين بيتحسب في نفس التشكيلة ──
select t.check('one test round for everything', public.fn_week_cutoff(now()) = public.fn_week_cutoff(now() + interval '30 days'));
select t.check('test season exists (chips work)', (select count(*) = 1 from public.seasons));
insert into public.matches (teams, date_time, week) values (array['أ', 'ب'], now() + interval '14 days', 2);
insert into public.lineups (match_id, player_id, status)
select (select id from public.matches where week = 2), id, 'starting' from public.players;
insert into public.events (match_id, player_id, type) select (select id from public.matches where week = 2), id, 'goal' from public.players where name = 'ه';
select t.check('second match adds to the same round (captain goal +10)',
  (select points = 28 from public.user_round_points where user_id = '00000000-0000-0000-0000-000000000001'));
select t.check('league total counts all points right away (no approval wait)',
  (select total_points = 28 from public.profiles where id = '00000000-0000-0000-0000-000000000001'));
insert into public.leagues (name, type) values ('الدوري العام', 'global');
select t.check('global league: top = 28 points, ranked first',
  (select rank = 1 and points = 28 from public.league_standings((select id from public.leagues where type = 'global')) limit 1));

-- ── خماسي/سداسي: الأساسي ≤ الملعب · الفريق ≤ ٧ ──
insert into public.players (name, team, position) values ('ز', 'أ', 'MID'), ('ح٩', 'أ', 'GK'), ('س', 'أ', 'DEF'), ('ص', 'أ', 'DEF');
select t.expect_fail('6th starter on a 5-a-side pitch',
  $q$insert into public.lineups (match_id, player_id, status) select (select id from public.matches where week = 1), id, 'starting' from public.players where name = 'ز'$q$);
update public.matches set format = 6 where week = 1;
insert into public.lineups (match_id, player_id, status) select (select id from public.matches where week = 1), id, 'starting' from public.players where name = 'ز';
select t.expect_fail('second starting GK',
  $q$insert into public.lineups (match_id, player_id, status) select (select id from public.matches where week = 1), id, 'starting' from public.players where name = 'ح٩'$q$);
insert into public.lineups (match_id, player_id, status) select (select id from public.matches where week = 1), id, 'bench' from public.players where name = 'س';
select t.expect_fail('8th player in the squad',
  $q$insert into public.lineups (match_id, player_id, status) select (select id from public.matches where week = 1), id, 'bench' from public.players where name in ('ص', 'ح٩')$q$);
select t.check('6-a-side squad of 7 saved', (select count(*) = 7 from public.lineups l join public.players p on p.id = l.player_id
  where l.match_id = (select id from public.matches where week = 1) and p.team = 'أ'));

-- ── حركة الترتيب + ملخص الجولة ──
select public.fn_snapshot_ranks();
select t.check('rank snapshot taken', (select prev_rank is not null from public.profiles where id = '00000000-0000-0000-0000-000000000001'));
select t.check('standings return movement', (select moved is not null from public.league_standings((select id from public.leagues where type = 'global')) limit 1));
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.check('round recap: points + best pick + captain',
  (select points = 28 and best_name = 'ه' and captain_name = 'ه' and captain_points = 10 from public.my_round_recap(public.fn_week_cutoff(now()))));
reset role;

-- ── دوري المناطق ──
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.check('zone league: my zone first with my points', (select rank = 1 and mine and total >= 28 from public.zone_standings() limit 1));
reset role;

-- ── البطولات ──
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
create temp table _t (k text primary key, id uuid);
insert into _t values ('league', public.create_tournament('دوري بدر', 'league', 4, 0, now() + interval '1 day'));
select public.add_tournament_team((select id from _t where k = 'league'), x) from unnest(array['أ', 'ب', 'ج']) x;
select public.draw_tournament((select id from _t where k = 'league'));
reset role;
select t.check('league: 3 teams → 3 matches', (select count(*) = 3 from public.matches where tournament_id = (select id from _t where k = 'league')));
select t.check('league matches belong to the organizer', (select bool_and(organizer_id = '00000000-0000-0000-0000-00000000000b') from public.matches where tournament_id = (select id from _t where k = 'league')));
-- أ تكسب الكل
insert into public.lineups (match_id, player_id, status)
select m.id, p.id, 'bench' from public.matches m, public.players p
where m.tournament_id = (select id from _t where k = 'league') and p.name = 'ز' and 'أ' = any(m.teams)
on conflict do nothing;
insert into public.events (match_id, player_id, type)
select m.id, (select id from public.players where name = 'ز'), 'goal' from public.matches m
where m.tournament_id = (select id from _t where k = 'league') and 'أ' = any(m.teams);
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select public.predict_champion((select id from _t where k = 'league'), 'أ');
reset role;
update public.matches set status = 'finished' where tournament_id = (select id from _t where k = 'league');
select t.check('league champion = top of table', (select champion = 'أ' and status = 'finished' from public.tournaments where id = (select id from _t where k = 'league')));
select t.check('standings: أ 6 pts', (select pts = 6 from public.tournament_standings((select id from _t where k = 'league')) where team = 'أ'));
select t.check('champion prediction +10 in bonus', public.fn_user_bonus('00000000-0000-0000-0000-000000000001') >= 10);
select t.check('awards: top scorer', (select name = 'ز' from public.tournament_awards((select id from _t where k = 'league')) where award = 'scorer'));

-- خروج المغلوب بـ ٣ فرق: فريق واخد راحة → النهائي بيتعمل لوحده → البطل
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into _t values ('ko', public.create_tournament('كاس بدر', 'knockout', 4, 0, now() + interval '1 day'));
select public.add_tournament_team((select id from _t where k = 'ko'), x) from unnest(array['أ', 'ب', 'ج']) x;
select public.draw_tournament((select id from _t where k = 'ko'));
reset role;
select t.check('knockout: 1 semi + bye', (select count(*) = 1 from public.matches where tournament_id = (select id from _t where k = 'ko')));
update public.matches set status = 'finished' where tournament_id = (select id from _t where k = 'ko') and stage = 'نص النهائي';
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
select public.set_match_winner((select id from public.matches where tournament_id = (select id from _t where k = 'ko') and stage = 'نص النهائي'),
  (select teams[1] from public.matches where tournament_id = (select id from _t where k = 'ko') and stage = 'نص النهائي'));
reset role;
select t.check('final created after the semi (draw decided by organizer)',
  (select count(*) = 1 from public.matches where tournament_id = (select id from _t where k = 'ko') and stage = 'النهائي'));
update public.matches set status = 'finished' where tournament_id = (select id from _t where k = 'ko') and stage = 'النهائي';
update public.matches set winner = teams[2] where tournament_id = (select id from _t where k = 'ko') and stage = 'النهائي';
select t.check('knockout champion crowned', (select champion is not null and status = 'finished' from public.tournaments where id = (select id from _t where k = 'ko')));

-- مجموعات: ٤ فرق في مجموعتين → كل مجموعة ماتش → خروج المغلوب
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
insert into _t values ('groups', public.create_tournament('بطولة المجموعات', 'groups', 4, 2, now() + interval '1 day'));
select public.add_tournament_team((select id from _t where k = 'groups'), x) from unnest(array['أ', 'ب', 'ج', 'د']) x;
select public.draw_tournament((select id from _t where k = 'groups'));
reset role;
select t.check('groups: 2 group matches', (select count(*) = 2 from public.matches where tournament_id = (select id from _t where k = 'groups')));
update public.matches set status = 'finished' where tournament_id = (select id from _t where k = 'groups');
select t.as_user('00000000-0000-0000-0000-00000000000b');
set role authenticated;
select public.start_knockout((select id from _t where k = 'groups'));
reset role;
select t.check('groups → knockout semis created', (select count(*) = 2 from public.matches where tournament_id = (select id from _t where k = 'groups') and stage = 'نص النهائي'));
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
select t.expect_fail('user cannot draw a tournament', $q$select public.draw_tournament((select id from _t where k = 'groups'))$q$);
select t.expect_fail('user cannot add teams', $q$select public.add_tournament_team((select id from _t where k = 'groups'), 'هـ')$q$);
reset role;
