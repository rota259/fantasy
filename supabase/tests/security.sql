-- اختبار اختراق: يوزر عادي (وزائر) بيحاول يعمل كل حاجة مش من حقه — كل سطر لازم يتمنع.
-- ملحوظة: الـ RLS في التعديل والمسح مبيرميش خطأ — بيعدّي صفر صفوف. فبنتأكد إن القيمة متغيّرتش.
create schema t;
grant usage on schema t to anon, authenticated;
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
  select set_config('request.jwt.claim.sub', coalesce(u::text, ''), false);
$$;
grant execute on function t.as_user(uuid) to anon, authenticated;

-- ── الداتا ──
-- زي Supabase: الأدوار عندها صلاحية على جدول الملفات، والـ RLS هي اللي بتفرز
grant select, insert, update, delete on storage.objects to anon, authenticated;
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-00000000000a', 'admin@t.co', jsonb_build_object('name', 'أدمن', 'phone', '0100', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-000000000001', 'u1@t.co', jsonb_build_object('name', 'يوزر١', 'phone', '0102', 'zone_id', (select id from public.zones where name = 'بدر'))),
 ('00000000-0000-0000-0000-000000000002', 'u2@t.co', jsonb_build_object('name', 'يوزر٢', 'phone', '0103', 'zone_id', (select id from public.zones where name = 'بدر')));
update public.profiles set role = 'manager' where id = '00000000-0000-0000-0000-00000000000a';
insert into public.teams (name, owner_id) values ('نسور', '00000000-0000-0000-0000-00000000000a');
insert into public.players (id, name, team, position, zone_id) values
 ('10000000-0000-0000-0000-000000000001', 'لاعب١', 'نسور', 'FWD', (select id from public.zones where name = 'بدر'));
insert into public.matches (id, teams, date_time, zone_id) values
 ('20000000-0000-0000-0000-000000000001', array['نسور', 'صقور'], now() + interval '1 day', (select id from public.zones where name = 'بدر'));
insert into public.venues (id, name, price, phone, owner_id) values
 ('30000000-0000-0000-0000-000000000001', 'ملعب يوزر٢', 200, '01000000000', '00000000-0000-0000-0000-000000000002');
insert into public.bookings (venue_id, user_id, day, hour) values
 ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', current_date + 1, 20);
insert into public.notifications (title, body, kind, user_id, audience) values ('سر', 'ليوزر٢ بس', 'status', '00000000-0000-0000-0000-000000000002', 'user');
insert into public.leagues (id, name, type, owner_id, invite_code) values
 ('40000000-0000-0000-0000-000000000001', 'دوري خاص', 'private', '00000000-0000-0000-0000-000000000002', 'SECRET1');
insert into public.polls (id, kind, question, active) values ('50000000-0000-0000-0000-000000000001', 'goal_week', 'هدف الجولة', true);
insert into public.poll_options (id, poll_id, label) values
 ('60000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 'أ'),
 ('60000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000001', 'ب');

-- ── يوزر١ بيهاجم ──
select t.as_user('00000000-0000-0000-0000-000000000001');
set role authenticated;
update public.profiles set name = 'اتهكر' where id = '00000000-0000-0000-0000-000000000002';
delete from public.profiles where id = '00000000-0000-0000-0000-000000000002';
update public.profiles set zone_id = (select id from public.zones where name = 'الشروق'),
  referred_by = '00000000-0000-0000-0000-000000000002', is_active = true, role = 'manager' where id = auth.uid();
select t.expect_fail('write round_picks directly', $q$insert into public.round_picks (user_id, round_end, player_id, status)
  values (auth.uid(), public.fn_open_round(), '10000000-0000-0000-0000-000000000001', 'starting')$q$);
select t.expect_fail('write chip_uses directly', $q$insert into public.chip_uses (user_id, chip, season_id, half, week_cutoff)
  values (auth.uid(), 'triple', (select id from public.seasons limit 1), 1, public.fn_open_round())$q$);
select t.expect_fail('write round_transfers (erase my −4)', $q$insert into public.round_transfers (user_id, round_end, transfers, free) values (auth.uid(), public.fn_open_round(), 0, 99)$q$);
select t.expect_fail('add a match event', $q$insert into public.events (match_id, player_id, type) values ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'goal')$q$);
select t.expect_fail('create a match as a user', $q$insert into public.matches (teams, date_time) values (array['أ', 'ب'], now() + interval '1 day')$q$);
update public.matches set score_a = 9, status = 'finished' where id = '20000000-0000-0000-0000-000000000001';
select t.expect_fail('venue owned by someone else', $q$insert into public.venues (name, price, phone, owner_id) values ('x', 1, '0100000000', '00000000-0000-0000-0000-000000000002')$q$);
update public.venues set price = 1 where id = '30000000-0000-0000-0000-000000000001';
delete from public.venues where id = '30000000-0000-0000-0000-000000000001';
select t.expect_fail('book in someone else''s name', $q$insert into public.bookings (venue_id, user_id, day, hour) values ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', current_date + 2, 20)$q$);
select t.expect_fail('book a day in the past', $q$insert into public.bookings (venue_id, user_id, day, hour) values ('30000000-0000-0000-0000-000000000001', auth.uid(), current_date - 1, 20)$q$);
select t.expect_fail('book a slot already taken', $q$insert into public.bookings (venue_id, user_id, day, hour) values ('30000000-0000-0000-0000-000000000001', auth.uid(), current_date + 1, 20)$q$);
select t.expect_fail('book as confirmed', $q$insert into public.bookings (venue_id, user_id, day, hour, status) values ('30000000-0000-0000-0000-000000000001', auth.uid(), current_date + 3, 20, 'confirmed')$q$);
select t.check('cannot see other people''s bookings', (select count(*) = 0 from public.bookings));
select t.check('cannot see other people''s private notifications', (select count(*) = 0 from public.notifications where title = 'سر'));
select t.check('cannot see a private league I am not in', (select count(*) = 0 from public.leagues where invite_code = 'SECRET1'));
select t.expect_fail('join a private league without its code', $q$insert into public.league_members (league_id, user_id) values ('40000000-0000-0000-0000-000000000001', auth.uid())$q$);
select t.expect_fail('vote in someone else''s name', $q$insert into public.poll_votes (poll_id, option_id, user_id) values ('50000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002')$q$);
insert into public.poll_votes (poll_id, option_id, user_id) values ('50000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', auth.uid());
select t.expect_fail('vote twice', $q$insert into public.poll_votes (poll_id, option_id, user_id) values ('50000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000002', auth.uid())$q$);
select t.expect_fail('upload into someone else''s avatar folder', $q$insert into storage.objects (bucket_id, name, owner) values ('avatars', '00000000-0000-0000-0000-000000000002/me.jpg', auth.uid())$q$);
insert into storage.objects (bucket_id, name, owner) values ('avatars', '00000000-0000-0000-0000-000000000001/me.jpg', auth.uid());
select t.expect_fail('upload a photo for a player that is not mine', $q$insert into storage.objects (bucket_id, name, owner) values ('player-photos', '10000000-0000-0000-0000-000000000001/p.jpg', auth.uid())$q$);
select t.expect_fail('set a photo for a player that is not mine', $q$select public.set_player_photo('10000000-0000-0000-0000-000000000001', 'https://evil.example/x.jpg')$q$);
select t.expect_fail('read the push secret', $q$select value from private.settings$q$);
select t.expect_fail('check a guessed push secret', $q$select public.push_secret_ok('guess')$q$);
select t.expect_fail('admin users list', $q$select * from public.admin_users(null, null, 50)$q$);
select t.expect_fail('admin counts', $q$select public.admin_counts()$q$);
select t.expect_fail('publish team of the week', $q$select public.publish_totw(now(), 0, array[]::uuid[])$q$);
select t.expect_fail('broadcast to everyone', $q$insert into public.notifications (title, body, audience) values ('x', 'y', 'all')$q$);
select t.expect_fail('rename a team I do not own', $q$update public.teams set name = 'x' where name = 'نسور' returning 1/0$q$);
select t.expect_fail('a 10k-char review', $q$insert into public.venue_reviews (venue_id, user_id, stars, comment) values ('30000000-0000-0000-0000-000000000001', auth.uid(), 5, repeat('x', 10000))$q$);
reset role;

select t.check('other profile untouched', (select name = 'يوزر٢' from public.profiles where id = '00000000-0000-0000-0000-000000000002'));
select t.check('my role / zone / referrer untouched by direct update',
  (select role = 'user' and zone_id = (select id from public.zones where name = 'بدر') and referred_by is null
   from public.profiles where id = '00000000-0000-0000-0000-000000000001'));
select t.check('match untouched', (select score_a is null and status = 'upcoming' from public.matches where id = '20000000-0000-0000-0000-000000000001'));
select t.check('venue untouched', (select price = 200 from public.venues where id = '30000000-0000-0000-0000-000000000001'));

-- ── زائر من غير حساب ──
select t.as_user(null);
set role anon;
select t.expect_fail('anon writes a profile', $q$insert into public.profiles (id, name) values (gen_random_uuid(), 'x')$q$);
select t.expect_fail('anon reads bookings', $q$select 1 / (select count(*) from public.bookings)$q$);
select t.expect_fail('anon reads notifications', $q$select 1 / (select count(*) from public.notifications)$q$);
select t.expect_fail('anon reads venues', $q$select 1 / (select count(*) from public.venues)$q$);
select t.expect_fail('anon uploads a file', $q$insert into storage.objects (bucket_id, name) values ('avatars', 'x/y.jpg')$q$);
select t.check('anon log flood is capped (200 a minute for all visitors)',
  (select sum(public.log_events((select jsonb_agg(jsonb_build_object('level', 'warn', 'event', 'flood.anon')) from generate_series(1, 20))))
   from generate_series(1, 20)) = 200);
reset role;
