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
