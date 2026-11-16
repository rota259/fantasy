-- الجزء 5 من 7 — شغّل الأجزاء بالترتيب (اتعمل من migrate_all.sql بـ tool/split_sql.py)
-- ═══ 42. تحدّي الجولة: ٤ أنواع والمدير يختار ═══
-- المدير وهو بيعلن التحدّي بيختار نوع واحد أو أكتر (أو الأربعة):
--   diff   فرق الأهداف — صح = +٥، ولو صح ورا بعض السلسلة بتكبر: +٥ ← +٧ ← +١٠ (أول غلطة ترجّعها)
--   duel   مين فيهم؟ — لاعب من كل فريق، مين يجيب نقط أكتر في الماتش = +٣ (التعادل الاتنين صح)
--   quiz   ٣ أسئلة — مين يكسب · الأهداف أكتر من ٦ · مين يسجّل الأول: كل واحد +٢، والتلاتة صح +١٠
--   lowest المعكوس — أقل لاعب نقط من الأساسيين = +٤ (لو كذا واحد متعادلين أي حد فيهم صح)
alter table public.matches add column if not exists challenge_modes text[] not null default '{}';
alter table public.matches add column if not exists duel_a uuid references public.players(id) on delete set null;
alter table public.matches add column if not exists duel_b uuid references public.players(id) on delete set null;
update public.matches set challenge_modes = '{diff}' where is_challenge and challenge_modes = '{}';
alter table public.events add column if not exists created_at timestamptz not null default now();

-- إعدادات التحدّي بتتغيّر من set_challenge بس (مش من تعديل الماتش)
create or replace function public.trg_match_challenge_guard()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.challenge_modes := '{}'; new.duel_a := null; new.duel_b := null;
    else
      new.challenge_modes := old.challenge_modes; new.duel_a := old.duel_a; new.duel_b := old.duel_b;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists match_challenge_guard on public.matches;
create trigger match_challenge_guard before insert or update on public.matches
for each row execute function public.trg_match_challenge_guard();

create table if not exists public.challenge_answers (
  user_id     uuid references public.profiles(id) on delete cascade,
  match_id    uuid references public.matches(id) on delete cascade,
  duel_pick   uuid references public.players(id) on delete set null,
  q_winner    text check (q_winner in ('a', 'b', 'draw')),
  q_over      boolean,
  q_first     uuid references public.players(id) on delete set null,
  lowest_pick uuid references public.players(id) on delete set null,
  updated_at  timestamptz not null default now(),
  primary key (user_id, match_id)
);
create index if not exists challenge_answers_match on public.challenge_answers(match_id);
alter table public.challenge_answers enable row level security;
-- إجابات الناس تبان بعد ما الماتش يبدأ بس — والكتابة من answer_challenge
drop policy if exists "challenge answers read" on public.challenge_answers;
create policy "challenge answers read" on public.challenge_answers for select to authenticated using (
  user_id = auth.uid() or public.is_manager()
  or exists (select 1 from public.matches m where m.id = match_id and m.date_time <= now()
             and m.zone_id = (select p.zone_id from public.profiles p where p.id = auth.uid()))
);

-- إعلان التحدّي بالأنواع المختارة (+ لاعيبة «مين فيهم؟»)
drop function if exists public.set_challenge(uuid);
create or replace function public.set_challenge(p_match uuid, p_modes text[] default '{diff}',
                                                p_duel_a uuid default null, p_duel_b uuid default null)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches; v_modes text[]; ta text; tb text;
begin
  select * into m from public.matches where id = p_match;
  if not found then raise exception 'الماتش مش موجود'; end if;
  if not (public.is_manager() or (public.is_organizer() and m.organizer_id = auth.uid())) then
    raise exception 'التحدّي من ماتشاتك بس';
  end if;
  if m.status <> 'upcoming' or (now() >= m.date_time - 2 * public.fn_lock_lead() and not public.fn_test_mode()) then
    raise exception 'اختار ماتش لسه فاضل عليه أكتر من ساعتين (الناس تلحق تتوقّع)';
  end if;
  if m.is_challenge then raise exception 'الماتش ده تحدّي خلاص'; end if;
  if m.zone_id is null then raise exception 'الماتش ملوش منطقة'; end if;
  select array_agg(distinct x order by x) into v_modes from unnest(coalesce(p_modes, '{}')) x;
  if v_modes is null or not (v_modes <@ array['diff', 'duel', 'quiz', 'lowest']) then
    raise exception 'اختار نوع تحدّي واحد على الأقل';
  end if;
  if 'duel' = any(v_modes) then
    select team into ta from public.players where id = p_duel_a;
    select team into tb from public.players where id = p_duel_b;
    if ta is null or tb is null or ta = tb or not (ta = any(m.teams)) or not (tb = any(m.teams)) then
      raise exception '«مين فيهم؟» محتاج لاعب من كل فريق في الماتش';
    end if;
  else
    p_duel_a := null; p_duel_b := null;
  end if;
  if exists (select 1 from public.matches x
             where x.is_challenge and x.organizer_id is not distinct from m.organizer_id and x.id <> m.id
               and public.fn_week_cutoff(x.date_time) = public.fn_week_cutoff(m.date_time)) then
    raise exception 'فيه تحدّي من ماتشات المدير ده في الجولة دي خلاص';
  end if;
  update public.matches set is_challenge = true, challenge_modes = v_modes, duel_a = p_duel_a, duel_b = p_duel_b
  where id = p_match;
  perform public.fn_notify_match(p_match, '🎯 تحدّي الجولة',
    m.teams[1] || ' ضد ' || m.teams[2] || ' — ' || cardinality(v_modes)
      || case when cardinality(v_modes) = 1 then ' تحدّي' else ' تحدّيات' end || ' مستنيينك: جاوب صح واكسب نقط',
    'challenge');
end $$;
revoke all on function public.set_challenge(uuid, text[], uuid, uuid) from public, anon;
grant execute on function public.set_challenge(uuid, text[], uuid, uuid) to authenticated;

-- اليوزر يجاوب (مين فيهم · الـ٣ أسئلة · المعكوس) — لحد قفل التوقّع، ولأهل منطقة الماتش بس
create or replace function public.answer_challenge(p_match uuid, p_duel uuid default null, p_winner text default null,
                                                   p_over boolean default null, p_first uuid default null,
                                                   p_lowest uuid default null)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  select * into m from public.matches where id = p_match;
  if m.id is null or not m.is_challenge then raise exception 'ده مش تحدّي'; end if;
  if not public.fn_me_active() then raise exception 'حسابك موقوف — كلّم الإدارة'; end if;
  if public.fn_is_zone_manager() then raise exception 'حساب المدير مش بيتوقّع'; end if;
  if m.zone_id is distinct from (select zone_id from public.profiles where id = auth.uid()) then
    raise exception 'التحدّي ده لمنطقة تانية';
  end if;
  if m.status <> 'upcoming' or not (public.fn_test_mode() or now() < m.date_time - public.fn_lock_lead()) then
    raise exception 'التوقّع اتقفل';
  end if;
  if p_duel is not null and p_duel not in (m.duel_a, m.duel_b) then raise exception 'اختار واحد من الاتنين'; end if;
  if exists (select 1 from unnest(array[p_first, p_lowest]) x
             where x is not null and not exists (select 1 from public.players pl
                                                 where pl.id = x and pl.team = any(m.teams))) then
    raise exception 'اللاعب مش من الفريقين';
  end if;
  insert into public.challenge_answers (user_id, match_id, duel_pick, q_winner, q_over, q_first, lowest_pick)
  values (auth.uid(), p_match,
          case when 'duel' = any(m.challenge_modes) then p_duel end,
          case when 'quiz' = any(m.challenge_modes) then p_winner end,
          case when 'quiz' = any(m.challenge_modes) then p_over end,
          case when 'quiz' = any(m.challenge_modes) then p_first end,
          case when 'lowest' = any(m.challenge_modes) then p_lowest end)
  on conflict (user_id, match_id) do update set
    duel_pick = excluded.duel_pick, q_winner = excluded.q_winner, q_over = excluded.q_over,
    q_first = excluded.q_first, lowest_pick = excluded.lowest_pick, updated_at = now();
end $$;
revoke all on function public.answer_challenge(uuid, uuid, text, boolean, uuid, uuid) from public, anon;
grant execute on function public.answer_challenge(uuid, uuid, text, boolean, uuid, uuid) to authenticated;

-- نتيجة التحدّي بعد الماتش: مين كسب · أكتر من ٦ · أول هدّاف · الفايزين في «مين فيهم؟» · أقل الأساسيين نقط
create or replace function public.fn_challenge_result(p_match uuid)
returns table(winner text, over boolean, first_scorer uuid, duel_winners uuid[], lowest uuid[])
language sql stable security definer set search_path = public as $$
  with m as (select * from public.matches where id = p_match),
  pts as (
    select l.player_id, l.status, coalesce(x.points, 0) as p
    from m join public.lineups l on l.match_id = m.id
    left join public.fn_pmp(m.date_time - interval '1 second', m.date_time) x
      on x.match_id = m.id and x.player_id = l.player_id
  ), duel as (
    select d.id, coalesce((select pts.p from pts where pts.player_id = d.id), 0) as p
    from m, unnest(array[m.duel_a, m.duel_b]) d(id) where d.id is not null
  )
  select case when m.score_a > m.score_b then 'a' when m.score_b > m.score_a then 'b' else 'draw' end,
         m.score_a + m.score_b > 6,
         (select e.player_id from public.events e where e.match_id = m.id and e.type = 'goal'
          order by e.minute nulls last, e.created_at, e.id limit 1),
         (select array_agg(duel.id) from duel where duel.p = (select max(p) from duel)),
         (select array_agg(pts.player_id) from pts
          where pts.status = 'starting' and pts.p = (select min(p) from pts where status = 'starting'))
  from m where m.status = 'finished' and m.score_a is not null and m.score_b is not null;
$$;

-- نقط اليوزر من كل تحدّي خلص (المعتمد — وفي التجربة على طول): كل نوع لوحده + سلسلة فرق الأهداف
create or replace function public.fn_challenge_scores(p_user uuid)
returns table(match_id uuid, date_time timestamptz, diff_pts int, streak int, duel_pts int, quiz_pts int, lowest_pts int)
language sql stable security definer set search_path = public as $$
  with ms as (
    select m.* from public.matches m
    where m.is_challenge and m.status = 'finished' and m.score_a is not null
      and (m.review_status = 'approved' or (public.fn_test_mode() and m.review_status <> 'void'))
      and (exists (select 1 from public.predictions pr where pr.user_id = p_user and pr.match_id = m.id)
           or exists (select 1 from public.challenge_answers ca where ca.user_id = p_user and ca.match_id = m.id))
  ), d as (
    -- فرق الأهداف: التوقعات بالترتيب، وكل غلطة بتبدأ مجموعة جديدة (السلسلة)
    select ms.id, ms.date_time, (pr.score_a - pr.score_b = ms.score_a - ms.score_b) as ok,
           sum(case when pr.score_a - pr.score_b = ms.score_a - ms.score_b then 0 else 1 end)
             over (order by ms.date_time, ms.id) as grp
    from ms join public.predictions pr on pr.user_id = p_user and pr.match_id = ms.id
    where cardinality(ms.challenge_modes) = 0 or 'diff' = any(ms.challenge_modes)
  ), ds as (
    select d.id, d.ok, case when d.ok then row_number() over (partition by d.grp, d.ok order by d.date_time, d.id) else 0 end as streak
    from d
  )
  select ms.id, ms.date_time,
    coalesce(case ds.streak when 0 then 0 when 1 then 5 when 2 then 7 else 10 end, 0)::int,
    coalesce(ds.streak, 0)::int,
    (case when 'duel' = any(ms.challenge_modes) and ca.duel_pick = any(r.duel_winners) then 3 else 0 end)::int,
    (case when 'quiz' = any(ms.challenge_modes) then
       case when ca.q_winner = r.winner and ca.q_over = r.over and ca.q_first = r.first_scorer then 10
            else (case when ca.q_winner = r.winner then 2 else 0 end
                + case when ca.q_over = r.over then 2 else 0 end
                + case when ca.q_first = r.first_scorer then 2 else 0 end) end
     else 0 end)::int,
    (case when 'lowest' = any(ms.challenge_modes) and ca.lowest_pick = any(r.lowest) then 4 else 0 end)::int
  from ms
  left join ds on ds.id = ms.id
  left join public.challenge_answers ca on ca.user_id = p_user and ca.match_id = ms.id
  left join lateral public.fn_challenge_result(ms.id) r on true;
$$;

-- بونص التوقعات: تحدّي الجولة بأنواعه + توقّع بطل البطولة صح (+١٠)
create or replace function public.fn_user_bonus(p_user uuid)
returns int language sql stable security definer set search_path = public as $$
  select (coalesce((select sum(s.diff_pts + s.duel_pts + s.quiz_pts + s.lowest_pts)
                    from public.fn_challenge_scores(p_user) s), 0)
        + (select 10 * count(*) from public.tournament_predictions tp join public.tournaments t on t.id = tp.tournament_id
           where tp.user_id = p_user and t.champion is not null and lower(trim(tp.team)) = lower(trim(t.champion))))::int;
$$;

-- النتيجة/الاعتماد: إعادة حساب نقط الناس (+ اللي جاوبوا التحدّي) وإشعار اللي كسب منه
create or replace function public.trg_match_result()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (new.status, new.score_a, new.score_b) is distinct from (old.status, old.score_a, old.score_b) then
    perform public.fn_recalc_player(l.player_id) from public.lineups l
      join public.players pl on pl.id = l.player_id and pl.position = 'GK' where l.match_id = new.id;
    perform public.fn_recalc_round_players(public.fn_week_cutoff(new.date_time),
      array(select id from public.players where team = any(new.teams)));
  end if;
  if new.review_status is distinct from old.review_status
     or (new.is_challenge and new.status is distinct from old.status)
     or (new.review_status = 'approved' and (new.score_a, new.score_b, new.is_challenge)
           is distinct from (old.score_a, old.score_b, old.is_challenge)) then
    update public.profiles set total_points = public.fn_user_points(id), badges_dirty = true
    where id in (select user_id from public.picks where match_id = new.id
                 union select user_id from public.predictions where match_id = new.id
                 union select user_id from public.challenge_answers where match_id = new.id);
    perform public.fn_recalc_round_players(public.fn_week_cutoff(new.date_time),
      array(select id from public.players where team = any(new.teams)));
    if new.is_challenge and new.review_status = 'approved' and old.review_status is distinct from 'approved' then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🎯 كسبت +' || w.pts || ' من تحدّي الجولة',
             new.teams[1] || ' ' || new.score_a || ' - ' || new.score_b || ' ' || new.teams[2]
               || case when w.streak >= 2 then ' · سلسلة ' || w.streak || ' 🔥' else '' end,
             'challenge', w.user_id, new.id
      from (select u.user_id, s.diff_pts + s.duel_pts + s.quiz_pts + s.lowest_pts as pts, s.streak
            from (select user_id from public.predictions where match_id = new.id
                  union select user_id from public.challenge_answers where match_id = new.id) u
            cross join lateral public.fn_challenge_scores(u.user_id) s
            where s.match_id = new.id) w
      where w.pts > 0;
    end if;
  end if;
  return null;
end $$;

-- (للشاشة) تحدّيات منطقتي: الأنواع · لاعيبة الفريقين · إجاباتي · النتيجة ونقطي بعد الماتش · سلسلتي
create or replace function public.challenge_board()
returns jsonb language sql stable security definer set search_path = public as $$
  with me as (select id, zone_id from public.profiles where id = auth.uid()),
  ms as (
    select m.* from public.matches m, me
    where m.is_challenge and m.zone_id = me.zone_id and m.date_time > now() - interval '7 days'
  ), sc as (select * from public.fn_challenge_scores(auth.uid()))
  select jsonb_build_object(
    'streak', coalesce((select sc.streak from sc where sc.diff_pts is not null
                        and exists (select 1 from public.predictions pr where pr.user_id = auth.uid() and pr.match_id = sc.match_id)
                        order by sc.date_time desc, sc.match_id desc limit 1), 0),
    'items', coalesce((select jsonb_agg(jsonb_build_object(
      'match_id', ms.id,
      'modes', case when cardinality(ms.challenge_modes) = 0 then array['diff'] else ms.challenge_modes end,
      'duel_a', ms.duel_a, 'duel_b', ms.duel_b,
      'players', (select coalesce(jsonb_agg(jsonb_build_object('id', pl.id, 'name', pl.name, 'team', pl.team,
                                                              'gk', pl.position = 'GK') order by pl.team, pl.name), '[]')
                  from public.players pl where pl.team = any(ms.teams)),
      'mine', (select to_jsonb(ca) - 'user_id' - 'match_id' from public.challenge_answers ca
               where ca.user_id = auth.uid() and ca.match_id = ms.id),
      'result', (select to_jsonb(r) from public.fn_challenge_result(ms.id) r),
      'points', (select jsonb_build_object('diff', sc.diff_pts, 'duel', sc.duel_pts, 'quiz', sc.quiz_pts,
                                           'lowest', sc.lowest_pts, 'streak', sc.streak)
                 from sc where sc.match_id = ms.id)
    )) from ms), '[]'));
$$;
revoke all on function public.challenge_board() from public, anon;
grant execute on function public.challenge_board() to authenticated;

-- (لتفاصيل النقط) التحدّيات اللي كسبت منها: الماتش + كام نقطة (بكل الأنواع والسلسلة)
create or replace function public.my_challenge_wins()
returns setof jsonb language sql stable security definer set search_path = public as $$
  select to_jsonb(m) || jsonb_build_object('bonus', s.diff_pts + s.duel_pts + s.quiz_pts + s.lowest_pts)
  from public.fn_challenge_scores(auth.uid()) s join public.matches m on m.id = s.match_id
  where s.diff_pts + s.duel_pts + s.quiz_pts + s.lowest_pts > 0
  order by m.date_time desc;
$$;
revoke all on function public.my_challenge_wins() from public, anon;
grant execute on function public.my_challenge_wins() to authenticated;

-- ═══ 43. المدير يرفع صور لاعيبته ═══
-- مدير المنطقة يرفع صورة لأي لاعب في فريق من فرقه (الفولدر = id اللاعب) — مش بس اللي هو ضافهم.
-- الأدمن زي ما هو لأي لاعب. الرابط بيتحفظ من set_player_photo (نفس الشرط).
create or replace function public.fn_can_edit_player(p_player uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_manager() or (public.fn_me_active() and exists (
    select 1 from public.players p
    where p.id = p_player
      and (p.created_by = auth.uid()
           or exists (select 1 from public.teams t
                      where lower(trim(t.name)) = lower(trim(p.team)) and t.owner_id = auth.uid()))));
$$;
grant execute on function public.fn_can_edit_player(uuid) to authenticated;

drop policy if exists "player photos organizer write" on storage.objects;
create policy "player photos organizer write" on storage.objects for insert to authenticated
  with check (bucket_id = 'player-photos'
              and (storage.foldername(name))[1] ~ '^[0-9a-fA-F-]{36}$'
              and public.fn_can_edit_player(((storage.foldername(name))[1])::uuid));

create or replace function public.set_player_photo(p_player uuid, p_url text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.fn_can_edit_player(p_player) then raise exception 'اللاعب ده مش في فرقك'; end if;
  if p_url is null or p_url !~ '^https://' or length(p_url) > 600 then raise exception 'رابط الصورة غلط'; end if;
  update public.players set image_url = p_url where id = p_player;
end $$;
revoke all on function public.set_player_photo(uuid, text) from public, anon;
grant execute on function public.set_player_photo(uuid, text) to authenticated;

-- ═══ 44. قفل تسريب الإيميل من رقم الموبايل ═══
-- قبل كده أي حد (حتى من غير حساب) كان يقدر يسأل email_for_phone ويعرف إيميل أي رقم.
-- دلوقتي الدخول و«نسيت كلمة السر» بالرقم بيتعملوا في السيرفر (Edge Function: auth-phone)،
-- والإيميل مبيطلعش بره. الدالتين دول للسيرفر بس، ومعاهم عدّاد محاولات لكل رقم ضد التخمين.
revoke execute on function public.email_for_phone(text) from public, anon, authenticated;

create table if not exists private.phone_auth_attempts (
  phone text not null,
  at    timestamptz not null default now()
);
create index if not exists phone_auth_attempts_idx on private.phone_auth_attempts(phone, at desc);

-- إيميل الرقم + تسجيل المحاولة. أكتر من p_max محاولة في ربع ساعة لنفس الرقم = too_many.
create or replace function public.phone_auth_email(p text, p_max int default 10)
returns text language plpgsql security definer set search_path = public, private as $$
declare n int;
begin
  if p is null or length(p) < 6 or length(p) > 20 then return null; end if;
  delete from private.phone_auth_attempts where at < now() - interval '1 day';
  select count(*) into n from private.phone_auth_attempts
  where phone = p and at > now() - interval '15 minutes';
  if n >= greatest(p_max, 1) then raise exception 'too_many'; end if;
  insert into private.phone_auth_attempts (phone) values (p);
  return (select email from public.profiles where phone = p limit 1);
end $$;
revoke all on function public.phone_auth_email(text, int) from public, anon, authenticated;
grant execute on function public.phone_auth_email(text, int) to service_role;

-- ═══ 45. البطولات: المنظّم يحدد مواعيد الماتشات + فانتازي لكل بطولة ═══

-- ── (أ) المواعيد: القرعة بتعمل الماتشات من غير ميعاد، والمنظّم يحدده لكل ماتش ──
-- time_set = false → الماتش لسه «ميعاده متحددش»: تاريخه مؤقت بعيد (مبيظهرش في الماتشات الجاية ولا بيتلعب)
-- لحد ما المنظّم يحدده من صفحة البطولة — وبعدها يبقى ماتش عادي (تشكيلة · أحداث · نتيجة).
alter table public.matches add column if not exists time_set boolean not null default true;

create or replace function public.fn_tournament_match(p_t uuid, a text, b text, p_stage text, p_day int)
returns uuid language plpgsql security definer set search_path = public as $$
declare t public.tournaments; mid uuid; n int;
begin
  select * into t from public.tournaments where id = p_t;
  select count(*) into n from public.matches where tournament_id = p_t;
  insert into public.matches (teams, date_time, week, organizer_id, tournament_id, stage, zone_id, time_set)
  values (array[a, b],
          -- مؤقت (أحد ٤ يناير ٢٠٩٩) بنفس ترتيب القرعة — المنظّم هيحدد الميعاد الحقيقي
          timestamptz '2099-01-04 12:00:00+00' + p_day * interval '10 minutes' + n * interval '1 second',
          0,
          case when exists (select 1 from public.profiles where id = t.created_by and role = 'organizer')
               then t.created_by end, p_t, p_stage, t.zone_id, false)
  returning id into mid;
  return mid;
end $$;

-- ماتش ميعاده متحددش مينفعش يخلص
create or replace function public.trg_match_time_guard()
returns trigger language plpgsql as $$
begin
  if not new.time_set and new.status = 'finished' then
    raise exception 'حدّد ميعاد الماتش الأول';
  end if;
  if current_user in ('authenticated', 'anon') then
    new.time_set := case when tg_op = 'INSERT' then true else old.time_set end;
  end if;
  return new;
end $$;
drop trigger if exists match_time_guard on public.matches;
create trigger match_time_guard before insert or update on public.matches
for each row execute function public.trg_match_time_guard();

-- (منظّم البطولة / الأدمن) تحديد أو تغيير ميعاد ماتش بطولة — قبل ما الماتش يبدأ
drop function if exists public.set_tournament_match_time(uuid, timestamptz);
create or replace function public.set_tournament_match_time(p_match uuid, p_time timestamptz, p_duration int default 60)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  select * into m from public.matches where id = p_match;
  if m.id is null or m.tournament_id is null then raise exception 'ده مش ماتش بطولة'; end if;
  if not public.fn_runs_tournament(m.tournament_id) then raise exception 'منظّم البطولة بس اللي يحدد المواعيد'; end if;
  if m.status <> 'upcoming' then raise exception 'الماتش خلص'; end if;
  if exists (select 1 from public.events e where e.match_id = p_match) or (m.time_set and m.date_time <= now()) then
    raise exception 'الماتش بدأ — مينفعش تغيّر ميعاده';
  end if;
  if p_time is null or (p_time < now() + interval '30 minutes' and not public.fn_test_mode()) then
    raise exception 'الميعاد لازم يكون بعد نص ساعة على الأقل';
  end if;
  if p_time > now() + interval '180 days' then raise exception 'الميعاد بعيد أوي'; end if;
  update public.matches set date_time = p_time, time_set = true, end_warned = false,
         duration_min = least(greatest(coalesce(p_duration, 60), 20), 300)
  where id = p_match;
  perform public.fn_notify_match(p_match, '🏆 ميعاد ماتش البطولة',
    m.teams[1] || ' ضد ' || m.teams[2] || coalesce(' · ' || m.stage, '') || ' — '
      || to_char(p_time at time zone 'Africa/Cairo', 'DD/MM HH24:MI'), 'match');
end $$;
revoke all on function public.set_tournament_match_time(uuid, timestamptz, int) from public, anon;
grant execute on function public.set_tournament_match_time(uuid, timestamptz, int) to authenticated;

-- ── (ب) فانتازي البطولة: كل بطولة بتشكيلة لوحدها ──
-- أهل منطقة البطولة بيختاروا ٥ لاعيبة من فرق البطولة (حارس + ٤ · بحد أقصى ٢ من نفس الفريق) وكابتن ×٢.
-- تقدر تغيّر تشكيلتك بين الماتشات (مقفولة وأي ماتش في البطولة شغال). لما ماتش يخلص تشكيلة كل واحد
-- بتتسجّل عليه (snapshot) — فالتغيير بعد كده مبيأثرش على اللي فات. الترتيب لكل بطولة لوحدها، وتقدر تلعب
-- في كذا بطولة في نفس الوقت. نقط فانتازي البطولة مبتدخلش إجمالي الدوري العام.
create table if not exists public.tournament_picks (
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  user_id       uuid not null references public.profiles(id) on delete cascade,
  player_id     uuid not null references public.players(id) on delete cascade,
  is_captain    boolean not null default false,
  primary key (tournament_id, user_id, player_id)
);
create index if not exists tournament_picks_user on public.tournament_picks(user_id);
alter table public.tournament_picks enable row level security;
drop policy if exists "tournament picks read" on public.tournament_picks;
create policy "tournament picks read" on public.tournament_picks for select to authenticated
  using (user_id = auth.uid() or public.is_manager());

-- تشكيلة كل يوزر وقت ما الماتش خلص (القراية من الدوال بس)
create table if not exists public.tournament_pick_snaps (
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  match_id      uuid not null references public.matches(id) on delete cascade,
  user_id       uuid not null references public.profiles(id) on delete cascade,
  player_id     uuid not null references public.players(id) on delete cascade,
  is_captain    boolean not null default false,
  primary key (match_id, user_id, player_id)
);
create index if not exists tournament_pick_snaps_t on public.tournament_pick_snaps(tournament_id, user_id);
alter table public.tournament_pick_snaps enable row level security;

-- فيه ماتش في البطولة شغال دلوقتي؟ (التشكيلات مقفولة لحد ما يخلص)
create or replace function public.fn_tournament_live(p_t uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.matches m
                 where m.tournament_id = p_t and m.status = 'upcoming' and m.time_set and m.date_time <= now());
$$;

create or replace function public.save_tournament_picks(p_t uuid, p_players uuid[], p_captain uuid)
returns void language plpgsql security definer set search_path = public as $$
declare t public.tournaments; ids uuid[];
begin
  select * into t from public.tournaments where id = p_t;
  if t.id is null then raise exception 'البطولة مش موجودة'; end if;
  if not public.fn_me_active() then raise exception 'حسابك موقوف — كلّم الإدارة'; end if;
  if public.fn_is_zone_manager() then raise exception 'حساب المدير مش بيلعب فانتازي'; end if;
  if t.zone_id is distinct from (select zone_id from public.profiles where id = auth.uid()) then
    raise exception 'البطولة دي لمنطقة تانية';
  end if;
  if t.status = 'finished' then raise exception 'البطولة خلصت'; end if;
  if public.fn_tournament_live(p_t) then raise exception 'فيه ماتش في البطولة شغال — غيّر تشكيلتك بعد ما يخلص'; end if;
  select array_agg(distinct x) into ids from unnest(coalesce(p_players, '{}')) x;
  if coalesce(cardinality(ids), 0) <> 5 then raise exception 'اختار ٥ لاعيبة (حارس + ٤)'; end if;
  if (select count(*) from public.players pl where pl.id = any(ids)
        and exists (select 1 from public.tournament_teams tt
                    where tt.tournament_id = p_t and tt.status = 'approved'
                      and lower(trim(tt.team)) = lower(trim(pl.team)))) <> 5 then
    raise exception 'كل اللاعيبة لازم يكونوا من فرق البطولة';
  end if;
  if (select count(*) from public.players pl where pl.id = any(ids) and pl.position = 'GK') <> 1 then
    raise exception 'لازم حارس واحد بالظبط';
  end if;
  if exists (select 1 from public.players pl where pl.id = any(ids) group by lower(trim(pl.team)) having count(*) > 2) then
    raise exception 'بحد أقصى لاعبين من نفس الفريق';
  end if;
  if p_captain is null or not (p_captain = any(ids)) then raise exception 'اختار الكابتن من تشكيلتك'; end if;
  delete from public.tournament_picks where tournament_id = p_t and user_id = auth.uid();
  insert into public.tournament_picks (tournament_id, user_id, player_id, is_captain)
  select p_t, auth.uid(), x, x = p_captain from unnest(ids) x;
end $$;
revoke all on function public.save_tournament_picks(uuid, uuid[], uuid) from public, anon;
grant execute on function public.save_tournament_picks(uuid, uuid[], uuid) to authenticated;

-- الماتش خلص → تشكيلات البطولة بتتسجّل عليه (لاعيبة الفريقين بس)
create or replace function public.trg_tournament_snap()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.tournament_id is not null and new.status = 'finished' and old.status is distinct from 'finished' then
    insert into public.tournament_pick_snaps (tournament_id, match_id, user_id, player_id, is_captain)
    select new.tournament_id, new.id, tp.user_id, tp.player_id, tp.is_captain
    from public.tournament_picks tp join public.players pl on pl.id = tp.player_id
    where tp.tournament_id = new.tournament_id and pl.team = any(new.teams)
    on conflict do nothing;
  end if;
  return null;
end $$;
drop trigger if exists tournament_snap on public.matches;
create trigger tournament_snap after update on public.matches
for each row execute function public.trg_tournament_snap();

-- نقط كل لاعب في كل ماتش خلص في البطولة
create or replace function public.fn_tournament_pmp(p_t uuid)
returns table(match_id uuid, player_id uuid, points int)
language sql stable security definer set search_path = public as $$
  select x.match_id, x.player_id, x.points
  from public.matches m
  cross join lateral public.fn_pmp(m.date_time - interval '1 second', m.date_time) x
  where m.tournament_id = p_t and m.status = 'finished' and m.review_status <> 'void' and x.match_id = m.id;
$$;

-- (للشاشة) فانتازي البطولة: مفتوح ولا لأ · لاعيبة فرق البطولة ونقطهم · تشكيلتي · نقطي · الترتيب
create or replace function public.tournament_fantasy_board(p_t uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  with t as (select * from public.tournaments where id = p_t),
  pm as (select * from public.fn_tournament_pmp(p_t)),
  sc as (
    select s.user_id, sum(coalesce(pm.points, 0) * case when s.is_captain then 2 else 1 end)::int as pts
    from public.tournament_pick_snaps s
    left join pm on pm.match_id = s.match_id and pm.player_id = s.player_id
    where s.tournament_id = p_t group by s.user_id
  ), us as (
    select u.user_id, coalesce(sc.pts, 0) as pts
    from (select distinct user_id from public.tournament_picks where tournament_id = p_t
          union select user_id from sc) u
    left join sc on sc.user_id = u.user_id
  ), rk as (
    select us.user_id, us.pts, p.name, rank() over (order by us.pts desc) as rnk
    from us join public.profiles p on p.id = us.user_id
  )
  select jsonb_build_object(
    'can_play', (select t.zone_id is not distinct from (select zone_id from public.profiles where id = auth.uid())
                        and not public.fn_is_zone_manager() from t),
    'finished', (select t.status = 'finished' from t),
    'live', public.fn_tournament_live(p_t),
    'players', coalesce((
      select jsonb_agg(jsonb_build_object('id', pl.id, 'name', pl.name, 'team', pl.team, 'gk', pl.position = 'GK',
               'image_url', pl.image_url,
               'points', coalesce((select sum(pm.points) from pm where pm.player_id = pl.id), 0))
             order by pl.team, (pl.position <> 'GK'), pl.name)
      from public.players pl
      where exists (select 1 from public.tournament_teams tt
                    where tt.tournament_id = p_t and tt.status = 'approved'
                      and lower(trim(tt.team)) = lower(trim(pl.team)))), '[]'),
    'mine', coalesce((select jsonb_agg(jsonb_build_object('id', tp.player_id, 'captain', tp.is_captain))
                      from public.tournament_picks tp where tp.tournament_id = p_t and tp.user_id = auth.uid()), '[]'),
    'my_points', coalesce((select rk.pts from rk where rk.user_id = auth.uid()), 0),
    'my_rank', (select rk.rnk from rk where rk.user_id = auth.uid()),
    'standings', coalesce((select jsonb_agg(jsonb_build_object('rank', x.rnk, 'name', x.name, 'points', x.pts,
                                                                'mine', x.user_id = auth.uid()) order by x.rnk, x.name)
                           from (select * from rk order by rk.rnk, rk.name limit 50) x), '[]'));
$$;
revoke all on function public.tournament_fantasy_board(uuid) from public, anon;
grant execute on function public.tournament_fantasy_board(uuid) to authenticated;

-- ═══ 46. فحص إشعارات الموبايل (push) ═══
-- (أدمن) إيه الناقص عشان الإشعار يوصل والأبلكيشن مقفول: الإضافة · رابط الفانكشن · آخر ردود الفانكشن · توكن جهازي.
create or replace function public.push_diagnostics()
returns jsonb language plpgsql security definer set search_path = public, private as $$
declare has_net boolean; u text; last jsonb := '[]'::jsonb;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  select exists (select 1 from pg_extension where extname = 'pg_net') into has_net;
  select value into u from private.settings where key = 'push_url';
  if has_net then
    begin
      execute $q$
        select coalesce(jsonb_agg(jsonb_build_object('status', x.status_code, 'error', x.error_msg,
                                                     'body', left(x.content::text, 160), 'at', x.created)), '[]')
        from (select status_code, error_msg, content, created from net._http_response
              order by created desc limit 5) x
      $q$ into last;
    exception when others then last := '[]'::jsonb;
    end;
  end if;
  return jsonb_build_object(
    'pg_net', has_net,
    'push_url', u,
    'my_token', (select fcm_token is not null from public.profiles where id = auth.uid()),
    'tokens', (select count(*) from public.profiles where fcm_token is not null),
    'last', last);
end $$;
revoke all on function public.push_diagnostics() from public, anon;
grant execute on function public.push_diagnostics() to authenticated;

-- (أدمن) رابط فانكشن الإشعارات للمشروع ده (بيتحط مرة واحدة) — لازم يكون رابط فانكشن push على supabase.co
create or replace function public.set_push_url(p_url text)
returns void language plpgsql security definer set search_path = public, private as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  if p_url !~ '^https://[a-z0-9]{15,30}\.supabase\.co/functions/v1/push$' then
    raise exception 'الرابط لازم يكون: https://<project-ref>.supabase.co/functions/v1/push';
  end if;
  insert into private.settings (key, value) values ('push_url', p_url)
  on conflict (key) do update set value = excluded.value;
  perform public.fn_admin_log('push_url', p_url, '{}'::jsonb);
end $$;
revoke all on function public.set_push_url(text) from public, anon;
grant execute on function public.set_push_url(text) to authenticated;

-- (أدمن) إشعار تجربة لنفسي
create or replace function public.send_test_push()
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  insert into public.notifications (title, body, kind, user_id)
  values ('🔔 تجربة الإشعارات', 'لو شايف ده والأبلكيشن مقفول يبقى كله تمام ✓', 'match', auth.uid());
end $$;
revoke all on function public.send_test_push() from public, anon;
grant execute on function public.send_test_push() to authenticated;

-- ═══ 47. مدة الماتش والقفل التلقائي ═══
-- المدير بيحدد مدة الماتش (الافتراضي ساعة). الماتش بيبدأ في ميعاده وبيتقفل لوحده لما مدته تخلص.
-- قبل القفل بـ ١٠ دقايق بيوصل المدير إشعار، ويقدر يزوّد ربع ساعة / نص ساعة / ساعة من شاشة إدارة الماتش.
alter table public.matches add column if not exists duration_min int not null default 60;
alter table public.matches add column if not exists end_warned boolean not null default false;
do $$ begin
  alter table public.matches add constraint matches_duration check (duration_min between 20 and 300);
exception when duplicate_object then null; end $$;

-- (منظّم الماتش / الأدمن) زوّد وقت على ماتش لسه مخلصش: ١٥ · ٣٠ · ٦٠ دقيقة
create or replace function public.extend_match(p_match uuid, p_minutes int)
returns int language plpgsql security definer set search_path = public as $$
declare m public.matches; v int;
begin
  select * into m from public.matches where id = p_match;
  if m.id is null then raise exception 'الماتش مش موجود'; end if;
  if not (public.is_manager() or (public.is_organizer() and m.organizer_id = auth.uid())) then
    raise exception 'مش ماتشك';
  end if;
  if m.status <> 'upcoming' then raise exception 'الماتش خلص'; end if;
  if p_minutes not in (15, 30, 60) then raise exception 'زوّد ربع ساعة أو نص ساعة أو ساعة'; end if;
  if m.duration_min + p_minutes > 300 then raise exception 'أقصى مدة للماتش ٥ ساعات'; end if;
  update public.matches set duration_min = duration_min + p_minutes, end_warned = false
  where id = p_match returning duration_min into v;
  return v;
end $$;
revoke all on function public.extend_match(uuid, int) from public, anon;
grant execute on function public.extend_match(uuid, int) to authenticated;

-- كل دقيقة: نبّه المدير قبل القفل بـ ١٠ دقايق · واقفل الماتشات اللي مدتها خلصت (اللي ليها تشكيلة بس)
create or replace function public.fn_close_due_matches()
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (title, body, kind, user_id, match_id)
  select '⏱ الماتش هيقفل بعد ١٠ دقايق',
         m.teams[1] || ' ضد ' || m.teams[2] || ' — لو لسه بتلعبوا زوّد وقت من صفحة إدارة الماتش',
         'match', m.organizer_id, m.id
  from public.matches m
  where m.status = 'upcoming' and m.time_set and not m.end_warned and m.organizer_id is not null
    and now() >= m.date_time + (m.duration_min - 10) * interval '1 minute'
    and now() < m.date_time + m.duration_min * interval '1 minute'
    and exists (select 1 from public.lineups l where l.match_id = m.id);
  update public.matches m set end_warned = true
  where m.status = 'upcoming' and m.time_set and not m.end_warned
    and now() >= m.date_time + (m.duration_min - 10) * interval '1 minute';

  update public.matches m set status = 'finished'
  where m.status = 'upcoming' and m.time_set
    and now() >= m.date_time + m.duration_min * interval '1 minute'
    and exists (select 1 from public.lineups l where l.match_id = m.id);
end $$;

do $$ begin
  perform cron.schedule('khomasi-matches', '* * * * *', 'select public.fn_close_due_matches()');
exception when others then
  raise notice 'pg_cron مش متاح: القفل التلقائي للماتشات محتاجه — فعّله من Database → Extensions';
end $$;

-- ═══ 48. التحديث الإجباري ═══
-- الأدمن بيحدد أقل رقم نسخة (build) مسموح لكل منصة. الأبلكيشن بيسأل أول ما يفتح:
-- لو نسخته أقدم → شاشة «حدّث الأبلكيشن» ومبيفتحش غير لما يتحدّث.
create table if not exists public.app_config (
  key   text primary key,
  value text not null
);
alter table public.app_config enable row level security;
insert into public.app_config (key, value) values
  ('min_build_android', '0'), ('min_build_ios', '0'),
  ('store_android', ''), ('store_ios', ''),
  ('update_message', 'فيه نسخة جديدة من الخماسي — حدّث عشان تكمّل')
on conflict (key) do nothing;

-- (لأي حد — حتى قبل تسجيل الدخول) إعدادات النسخة
create or replace function public.get_app_config()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_object_agg(key, value), '{}'::jsonb) from public.app_config;
$$;
revoke all on function public.get_app_config() from public;
grant execute on function public.get_app_config() to anon, authenticated;

create or replace function public.set_app_config(p_key text, p_value text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  if p_key not in ('min_build_android', 'min_build_ios', 'store_android', 'store_ios', 'update_message') then
    raise exception 'إعداد مش معروف';
  end if;
  if p_key like 'min_build_%' and p_value !~ '^\d{1,6}$' then raise exception 'رقم النسخة لازم يبقى رقم'; end if;
  if p_key like 'store_%' and p_value <> '' and p_value !~ '^https://' then raise exception 'لينك المتجر لازم يبدأ بـ https://'; end if;
  if length(p_value) > 300 then raise exception 'القيمة طويلة'; end if;
  insert into public.app_config (key, value) values (p_key, p_value)
  on conflict (key) do update set value = excluded.value;
  perform public.fn_admin_log('app_config', p_key, jsonb_build_object('value', p_value));
end $$;
revoke all on function public.set_app_config(text, text) from public, anon;
grant execute on function public.set_app_config(text, text) to authenticated;

-- ═══ 49. الدوري العام بيتصفّر مع كل موسم ═══
-- إجمالي اليوزر (الدوري العام والترتيب ودوري المناطق والدوريات الخاصة) = نقط الموسم الحالي بس.
-- أول ما موسم جديد يبدأ الكل يرجع صفر. بين موسمين (لسه مفيش موسم جديد) بيفضل ترتيب آخر موسم خلص.
-- لو مفيش مواسم خالص، أو في وضع التجربة → كل النقط من أول يوم (زي الأول).
-- نقط المواسم القديمة مش بتتمسح: بتفضل في صفحة «تفاصيل نقطي» باختيار الموسم.
create or replace function public.fn_current_season()
returns public.seasons language sql stable security definer set search_path = public as $$
  select * from public.seasons
  where starts_at <= now()
  order by (now() < ends_at) desc, starts_at desc
  limit 1;
$$;

-- بونص التوقعات (تحدّي الجولة بأنواعه + بطل البطولة) جوه فترة
create or replace function public.fn_user_bonus_between(p_user uuid, p_from timestamptz, p_to timestamptz)
returns int language sql stable security definer set search_path = public as $$
  select (coalesce((select sum(s.diff_pts + s.duel_pts + s.quiz_pts + s.lowest_pts)
                    from public.fn_challenge_scores(p_user) s
                    where s.date_time > p_from and s.date_time <= p_to), 0)
        + (select 10 * count(*) from public.tournament_predictions tp join public.tournaments t on t.id = tp.tournament_id
           where tp.user_id = p_user and t.champion is not null and lower(trim(tp.team)) = lower(trim(t.champion))
             and t.starts_at > p_from and t.starts_at <= p_to))::int;
$$;

create or replace function public.fn_user_points(p_user uuid)
returns int language plpgsql stable security definer set search_path = public as $$
declare s public.seasons; f timestamptz := '-infinity'; t timestamptz := 'infinity';
begin
  if not public.fn_test_mode() then
    s := public.fn_current_season();
    if s.id is not null then f := s.starts_at; t := s.ends_at; end if;
  end if;
  return (coalesce((select sum(case when public.fn_test_mode() then r.points else r.final_points end)
                    from public.user_round_points r
                    where r.user_id = p_user and r.round_end > f and r.round_end <= t), 0)
          + coalesce((select sum(u.points) from public.user_match_points u
                      join public.matches m on m.id = u.match_id
                      where u.user_id = p_user and m.review_status = 'approved'
                        and m.date_time > f and m.date_time <= t), 0)
          + public.fn_user_bonus_between(p_user, f, t))::int;
end $$;

-- إعادة حساب إجمالي كل الناس (بداية موسم جديد أو تعديل تواريخ المواسم) — وأسهم الترتيب بتتصفّر
create or replace function public.fn_recalc_all_totals()
returns void language sql security definer set search_path = public as $$
  update public.profiles set total_points = public.fn_user_points(id), prev_rank = null, badges_dirty = true;
$$;

create or replace function public.trg_seasons_recalc()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_recalc_all_totals();
  return null;
end $$;
drop trigger if exists seasons_recalc on public.seasons;
create trigger seasons_recalc after insert or update or delete on public.seasons
for each statement execute function public.trg_seasons_recalc();

-- كل دقيقة (مع قفل الماتشات): لو موسم بدأ ولسه متصفّرش → صفّر الدوري وابعت إشعار للكل (مرة واحدة لكل موسم)
create or replace function public.fn_season_tick()
returns void language plpgsql security definer set search_path = public as $$
declare s public.seasons;
begin
  if public.fn_test_mode() then return; end if;
  s := public.fn_season_at(now());
  if s.id is null then return; end if;
  insert into public.app_jobs (key) values ('season_start:' || s.id) on conflict do nothing;
  if not found then return; end if;
  perform public.fn_recalc_all_totals();
  insert into public.notifications (title, body, kind, audience)
  values ('🏁 موسم جديد بدأ: ' || s.name, 'الدوري العام اتصفّر والكل بيبدأ من الأول — اعمل تشكيلتك', 'match', 'all');
end $$;

create or replace function public.fn_close_due_matches_and_season()
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_close_due_matches();
  perform public.fn_season_tick();
end $$;
do $$ begin
  perform cron.schedule('khomasi-matches', '* * * * *', 'select public.fn_close_due_matches_and_season()');
exception when others then
  raise notice 'pg_cron مش متاح: فعّله من Database → Extensions وشغّل الملف تاني';
end $$;

-- ═══ 50. نغمة كل إشعار + إشعار بداية الجولة وقبل الديدلاين وبداية الماتش ═══
-- sound = النغمة اللي الإشعار بيشتغل بيها (في الأبلكيشن، وفي قناة أندرويد والأبلكيشن مقفول):
--   goal الأهداف بس · match بداية ونهاية الماتش · lineup التشكيلة نزلت · round الجولة بدأت
--   deadline قبل الديدلاين · general أي حاجة تانية
alter table public.notifications add column if not exists sound text;

-- النغمة بتتحدد لوحدها لو الإشعار جاي من غيرها (من نوعه وعنوانه — العناوين دي ثابتة في الدوال اللي فوق)
create or replace function public.trg_notification_sound()
returns trigger language plpgsql as $$
begin
  if new.sound is null or new.sound not in ('goal', 'match', 'lineup', 'round', 'deadline', 'general') then
    new.sound := case
      when new.kind = 'event' and (new.title like 'جوووول%' or new.title like 'جول عكسي%') then 'goal'
      when new.kind = 'match' and new.title like 'انتهى الماتش%' then 'match'
      when new.kind = 'lineup' then 'lineup'
      else 'general' end;
  end if;
  return new;
end $$;
drop trigger if exists notification_sound on public.notifications;
create trigger notification_sound before insert on public.notifications
for each row execute function public.trg_notification_sound();

alter table public.matches add column if not exists start_notified boolean not null default false;

-- كل دقيقة: «الماتش بدأ» لأهل المنطقة (مرة لكل ماتش، ولو اتأخر أكتر من ربع ساعة بيتعدّى)
create or replace function public.fn_match_start_tick()
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (title, body, kind, match_id, audience, zone_id, sound)
  select '🟢 الماتش بدأ', m.teams[1] || ' ضد ' || m.teams[2] || ' — تابع الأحداث لايف', 'match', m.id, 'zone', m.zone_id, 'match'
  from public.matches m
  where m.status = 'upcoming' and m.time_set and not m.start_notified and m.zone_id is not null
    and m.date_time <= now() and m.date_time > now() - interval '15 minutes'
    and exists (select 1 from public.lineups l where l.match_id = m.id);
  update public.matches set start_notified = true
  where status = 'upcoming' and time_set and not start_notified and date_time <= now();
end $$;

-- كل دقيقة (في الوضع الحقيقي): قبل الديدلاين بساعتين (السبت ١ الظهر) + الجولة بدأت (السبت ٤ العصر) — مرة لكل جولة
create or replace function public.fn_round_tick()
returns void language plpgsql security definer set search_path = public as $$
declare o timestamptz; dl timestamptz; c timestamptz; st timestamptz;
begin
  if public.fn_test_mode() then return; end if;
  -- الجولة اللي تشكيلاتها لسه مفتوحة
  o := public.fn_open_round();
  dl := public.fn_round_deadline(o);
  if now() >= dl - interval '2 hours' and now() < dl then
    insert into public.app_jobs (key) values ('deadline:' || to_char(o at time zone 'UTC', 'YYYYMMDDHH24'))
    on conflict do nothing;
    if found then
      insert into public.notifications (title, body, kind, audience, sound, link)
      values ('⏰ فاضل ساعتين على الديدلاين', 'ثبّت تشكيلتك والكابتن قبل السبت ٣ العصر — بعدها التشكيلة بتتقفل',
              'lineup', 'all', 'deadline', 'team');
    end if;
  end if;
  -- الجولة اللي بتتلعب دلوقتي
  c := public.fn_week_cutoff(now());
  st := public.fn_round_start(c);
  if now() >= st and now() < st + interval '1 hour' then
    insert into public.app_jobs (key) values ('round_start:' || to_char(c at time zone 'UTC', 'YYYYMMDDHH24'))
    on conflict do nothing;
    if found then
      insert into public.notifications (title, body, kind, audience, sound, link)
      values ('🟢 الجولة بدأت', 'التشكيلات اتقفلت والماتشات شغالة — تابع نقطك لايف', 'match', 'all', 'round', 'home');
    end if;
  end if;
end $$;

create or replace function public.fn_close_due_matches_and_season()
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_match_start_tick();
  perform public.fn_close_due_matches();
  perform public.fn_season_tick();
  perform public.fn_round_tick();
end $$;

-- ═══ 51. نقط المشاركة: التشكيلة اتغيّرت → إعادة حساب نقط اللاعب واللي اختاروه ═══
-- (+٣ لكل أساسي — القاعدة نفسها في fn_score_points / fn_pmp فوق)
create or replace function public.trg_lineup_recalc()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.fn_recalc_player(old.player_id);
    perform public.fn_recalc_match(old.match_id);
    perform public.fn_recalc_round_players(
      public.fn_week_cutoff((select date_time from public.matches where id = old.match_id)), array[old.player_id]);
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.fn_recalc_player(new.player_id);
    perform public.fn_recalc_match(new.match_id);
    perform public.fn_recalc_round_players(
      public.fn_week_cutoff((select date_time from public.matches where id = new.match_id)), array[new.player_id]);
  end if;
  return null;
end $$;
drop trigger if exists lineup_recalc on public.lineups;
create trigger lineup_recalc after insert or update or delete on public.lineups
for each row execute function public.trg_lineup_recalc();

-- القواعد اتغيّرت (مشاركة +٣ · كل ٣ تصديات +١) → إعادة حساب كل الأرقام المتخزّنة مرة واحدة
do $$
begin
  if not exists (select 1 from public.app_jobs where key = 'rules_v2_recalc') then
    perform public.fn_recalc_player(id) from public.players;
    perform public.fn_recalc_users();
    insert into public.app_jobs (key) values ('rules_v2_recalc') on conflict do nothing;
  end if;
end $$;

-- ═══ 51-ب. السجلات (logs) — مكان واحد لكل حاجة بتحصل ═══
-- كل سطر = حدث منظّم (مش كلام): الوقت · المستوى · الخدمة · النسخة · الحدث · رقم الطلب · اليوزر · الخطأ.
--   service: app (الأبلكيشن) · db (السيرفر) · edge:push · edge:auth-phone
--   level:   debug · info · warn · error · fatal
-- الأبلكيشن بيبعت عن طريق log_events (بتنضّف وبتحدّ العدد) — محدش يقرا الجدول غير الأدمن (admin_logs).
-- ممنوع يتسجّل: كلمات سر · توكنات · أكواد التأكيد · محتوى الطلبات. الإيميل والرقم بيتغطّوا (a***@x.com).
-- الشرح الكامل: docs/LOGGING.md
create table if not exists public.app_logs (
  id          bigint generated always as identity primary key,
  ts          timestamptz not null default now(),   -- وقت الاستلام في السيرفر (UTC)
  client_ts   timestamptz,                          -- وقت الحدث على الجهاز
  level       text not null,
  service     text not null default 'app',
  env         text,
  version     text,
  event       text not null,                        -- اسم ثابت: auth.login.failed · http.error ...
  message     text,
  request_id  text,
  session_id  text,
  user_id     uuid,
  route       text,
  status      int,
  duration_ms int,
  error_type  text,
  error_stack text,
  fields      jsonb not null default '{}'::jsonb
);
create index if not exists app_logs_ts on public.app_logs (ts desc);
create index if not exists app_logs_level_ts on public.app_logs (level, ts desc);
create index if not exists app_logs_request on public.app_logs (request_id) where request_id is not null;
create index if not exists app_logs_user_ts on public.app_logs (user_id, ts desc) where user_id is not null;
alter table public.app_logs enable row level security;   -- مفيش سياسات = محدش يوصله من التطبيق

-- تغطية الإيميلات وأرقام الموبايلات في أي نص (لو اتسرّبوا في رسالة خطأ)
create or replace function public.fn_log_mask(p text)
returns text language sql immutable as $$
  select regexp_replace(
           regexp_replace(p, '([A-Za-z0-9._%+-])[A-Za-z0-9._%+-]*@([A-Za-z0-9.-]+)', '\1***@\2', 'g'),
           '(\+?\d{3})\d{4,9}(\d{2})', '\1*****\2', 'g');
$$;

-- شيل أي مفتاح حسّاس من الحقول (حماية تانية — الأبلكيشن بينضّف قبل ما يبعت)
create or replace function public.fn_log_clean(p jsonb)
returns jsonb language sql immutable as $$
  select coalesce(jsonb_object_agg(k, case when jsonb_typeof(v) = 'string' then to_jsonb(left(public.fn_log_mask(v #>> '{}'), 300)) else v end), '{}'::jsonb)
  from jsonb_each(case when jsonb_typeof(p) = 'object' then p else '{}'::jsonb end) e(k, v)
  where k !~* '(pass|token|secret|api_?key|authorization|cookie|otp|^code$|card|cvv|national)'
    and jsonb_typeof(v) in ('string', 'number', 'boolean', 'null');
$$;

-- تسجيل حدث من جوه السيرفر (الدوال والـ Edge Functions) — عمره ما يوقّف العملية الأصلية
create or replace function public.fn_log(p_level text, p_event text, p_message text default null,
                                         p_fields jsonb default '{}'::jsonb, p_service text default 'db',
                                         p_request_id text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.app_logs (level, service, event, message, user_id, fields, request_id)
  values (case when p_level in ('debug', 'info', 'warn', 'error', 'fatal') then p_level else 'info' end,
          left(coalesce(p_service, 'db'), 40), left(p_event, 60), left(public.fn_log_mask(p_message), 500),
          auth.uid(), public.fn_log_clean(p_fields), left(p_request_id, 64));
exception when others then null;
end $$;

-- (الأبلكيشن) دفعة أحداث: آخرها ٢٠ في النداء · ٦٠ كل ٥ دقايق لليوزر · ٢٠٠ في الدقيقة لكل الزوّار مع بعض
-- user_id بيتاخد من الجلسة في السيرفر — اللي الأبلكيشن يبعته مبيتصدّقش.
create or replace function public.log_events(p_events jsonb)
returns int language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); n int; room int;
begin
  if jsonb_typeof(p_events) <> 'array' then return 0; end if;
  if u is not null then
    select 60 - count(*) into room from public.app_logs where user_id = u and service = 'app' and ts > now() - interval '5 minutes';
  else
    select 200 - count(*) into room from public.app_logs where user_id is null and service = 'app' and ts > now() - interval '1 minute';
  end if;
  if room <= 0 then return 0; end if;
  insert into public.app_logs (client_ts, level, service, env, version, event, message, request_id, session_id,
                               user_id, route, status, duration_ms, error_type, error_stack, fields)
  select case when e->>'timestamp' ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}' then (e->>'timestamp')::timestamptz end,
         e->>'level', 'app', left(e->>'env', 20), left(e->>'version', 30), e->>'event',
         left(public.fn_log_mask(e->>'message'), 500), left(e->>'request_id', 64), left(e->>'session_id', 64),
         u, left(e->>'route', 120),
         case when e->>'status' ~ '^\d{1,3}$' then (e->>'status')::int end,
         case when e->>'duration_ms' ~ '^\d{1,7}$' then (e->>'duration_ms')::int end,
         left(e->>'error_type', 120), left(public.fn_log_mask(e->>'error_stack'), 4000),
         public.fn_log_clean(e->'fields')
  from (select e from jsonb_array_elements(p_events) e limit least(room, 20)) x
  where e->>'level' in ('debug', 'info', 'warn', 'error', 'fatal') and e->>'event' ~ '^[a-z0-9_.]{2,60}$';
  get diagnostics n = row_count;
  return n;
end $$;

-- عمليات الأدمن (تغيير دور · حظر · إعدادات ...) بتتسجّل كمان في السجل المركزي كحدث audit
create or replace function public.fn_admin_log(p_action text, p_target text, p_detail jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.admin_log (admin_id, action, target, detail) values (auth.uid(), p_action, p_target, p_detail);
  perform public.fn_log('info', 'audit.admin.' || regexp_replace(lower(p_action), '[^a-z0-9_]', '_', 'g'), null,
                        jsonb_build_object('target', left(p_target, 100)));
end $$;

-- (أدمن) بحث في السجلات: بالمستوى · بالخدمة · بنص (رقم الطلب / رقم اليوزر / اسم الحدث / نوع الخطأ)
create or replace function public.admin_logs(p_level text default null, p_search text default null,
                                             p_limit int default 100, p_before bigint default null)
returns setof public.app_logs language plpgsql stable security definer set search_path = public as $$
declare q text := nullif(trim(coalesce(p_search, '')), '');
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query
  select l.* from public.app_logs l
  where (p_before is null or l.id < p_before)
    and (p_level is null or l.level = p_level or (p_level = 'problems' and l.level in ('warn', 'error', 'fatal')))
    and (q is null or l.request_id = q or l.session_id = q or l.user_id::text = q
         or l.event ilike q || '%' or l.error_type ilike '%' || q || '%')
  order by l.id desc limit least(greatest(coalesce(p_limit, 100), 1), 300);
end $$;

-- (أدمن) لوحة السجلات: الأخطاء · الطلبات · السرعة · أكتر أخطاء · نبض المهام المجدولة
create or replace function public.admin_log_stats()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return jsonb_build_object(
    'errors_1h', (select count(*) from public.app_logs where level in ('error', 'fatal') and ts > now() - interval '1 hour'),
    'errors_24h', (select count(*) from public.app_logs where level in ('error', 'fatal') and ts > now() - interval '24 hours'),
    'warns_24h', (select count(*) from public.app_logs where level = 'warn' and ts > now() - interval '24 hours'),
    'failed_requests_1h', (select count(*) from public.app_logs where event like 'http.%' and ts > now() - interval '1 hour'),
    'p95_ms_1h', (select coalesce(percentile_cont(0.95) within group (order by duration_ms), 0)::int
                  from public.app_logs where duration_ms is not null and ts > now() - interval '1 hour'),
    'users_hit_24h', (select count(distinct user_id) from public.app_logs
                      where level in ('error', 'fatal') and ts > now() - interval '24 hours'),
    'top_errors', (select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) from (
                     select coalesce(error_type, event) as name, count(*) as n from public.app_logs
                     where level in ('error', 'fatal') and ts > now() - interval '24 hours'
                     group by 1 order by 2 desc limit 5) t),
    'tick_at', (select done_at from public.app_jobs where key = 'tick'),
    'watch_at', (select done_at from public.app_jobs where key = 'log_watch'),
    'rows', (select count(*) from public.app_logs));
end $$;

-- تنبيه للأدمنز (إشعار بيفتح شاشة السجلات) — مرة كل نص ساعة لكل نوع تنبيه
create or replace function public.fn_log_alert(p_key text, p_title text, p_body text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.app_jobs where key = 'alert:' || p_key and done_at > now() - interval '30 minutes') then
    return;
  end if;
  insert into public.app_jobs (key, done_at) values ('alert:' || p_key, now())
  on conflict (key) do update set done_at = excluded.done_at;
  insert into public.notifications (title, body, kind, user_id, link, sound)
  select p_title, left(p_body, 180), 'admin', pr.id, 'admin:logs', 'general'
  from public.profiles pr where pr.role = 'manager';
end $$;

-- كل ٥ دقايق: تنبيهات (قفزة أخطاء · خطأ جديد · مهمة مجدولة فشلت · محاولات دخول كتير) + مسح القديم
create or replace function public.fn_log_watch()
returns void language plpgsql security definer set search_path = public as $$
declare now_n int; base numeric; r record; keep int;
begin
  insert into public.app_jobs (key, done_at) values ('log_watch', now())
  on conflict (key) do update set done_at = excluded.done_at;

  -- قفزة أخطاء: آخر ٥ دقايق أكتر من ٥ أضعاف المعتاد (وعلى الأقل ١٠)
  select count(*) into now_n from public.app_logs where level in ('error', 'fatal') and ts > now() - interval '5 minutes';
  select count(*) / 288.0 into base from public.app_logs
  where level in ('error', 'fatal') and ts > now() - interval '24 hours 5 minutes' and ts <= now() - interval '5 minutes';
  if now_n >= greatest(10, 5 * base) then
    perform public.fn_log_alert('spike', '🚨 قفزة أخطاء في الأبلكيشن', now_n || ' خطأ في آخر ٥ دقايق — افتح السجلات');
  end if;

  -- نوع خطأ أول مرة يظهر (في آخر ٣٠ يوم)
  for r in select coalesce(l.error_type, l.event) as name, count(*) as n from public.app_logs l
           where l.level in ('error', 'fatal') and l.ts > now() - interval '5 minutes'
             and not exists (select 1 from public.app_logs o where o.level in ('error', 'fatal')
                             and o.ts <= now() - interval '5 minutes' and coalesce(o.error_type, o.event) = coalesce(l.error_type, l.event))
           group by 1 order by 2 desc limit 1 loop
    perform public.fn_log_alert('new_error', '🆕 خطأ جديد أول مرة يظهر', r.name);
  end loop;

  -- مهمة مجدولة فشلت (pg_cron بيسجّل كل تشغيلة: البداية · النهاية · النتيجة)
  if to_regclass('cron.job_run_details') is not null then
    execute $q$select count(*) from cron.job_run_details where status = 'failed' and start_time > now() - interval '10 minutes'$q$ into now_n;
    if now_n > 0 then
      perform public.fn_log('error', 'job.failed', 'pg_cron', jsonb_build_object('runs', now_n));
      perform public.fn_log_alert('cron', '⛔ مهمة مجدولة في السيرفر فشلت', now_n || ' تشغيلة فشلت في آخر ١٠ دقايق');
    end if;
  end if;

  -- محاولات دخول كتير على نفس الرقم (تخمين كلمة سر)
  if to_regclass('private.phone_auth_attempts') is not null then
    execute $q$select count(*) from (select phone from private.phone_auth_attempts
               where at > now() - interval '5 minutes' group by phone having count(*) > 10) x$q$ into now_n;
    if now_n > 0 then
      perform public.fn_log('warn', 'security.bruteforce', null, jsonb_build_object('phones', now_n));
      perform public.fn_log_alert('brute', '🔐 محاولات دخول كتير', now_n || ' رقم عليه أكتر من ١٠ محاولات في ٥ دقايق');
    end if;
  end if;

  -- مدة الحفظ: ٣٠ يوم (debug/info ١٤ يوم) — تتغيّر من app_config: log_retention_days
  keep := coalesce((select nullif(value, '')::int from public.app_config where key = 'log_retention_days'), 30);
  delete from public.app_logs where ts < now() - make_interval(days => keep);
  delete from public.app_logs where level in ('debug', 'info') and ts < now() - make_interval(days => least(keep, 14));
  delete from public.app_jobs where key like 'alert:%' and done_at < now() - interval '2 days';
end $$;

do $$ begin
  perform cron.schedule('khomasi-logs', '*/5 * * * *', 'select public.fn_log_watch()');
exception when others then
  raise notice 'pg_cron مش متاح: تنبيهات السجلات ومسح القديم محتاجينه';
end $$;

-- مستوى السجلات ومدة الحفظ بيتغيّروا من غير نسخة جديدة (log_level: debug · info · warn · error)
create or replace function public.set_app_config(p_key text, p_value text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  if p_key not in ('min_build_android', 'min_build_ios', 'store_android', 'store_ios', 'update_message',
                   'log_level', 'log_retention_days') then
    raise exception 'إعداد مش معروف';
  end if;
  if p_key like 'min_build_%' and p_value !~ '^\d{1,6}$' then raise exception 'رقم النسخة لازم يبقى رقم'; end if;
  if p_key like 'store_%' and p_value <> '' and p_value !~ '^https://' then raise exception 'لينك المتجر لازم يبدأ بـ https://'; end if;
  if p_key = 'log_level' and p_value not in ('debug', 'info', 'warn', 'error') then raise exception 'المستوى: debug · info · warn · error'; end if;
  if p_key = 'log_retention_days' and (p_value !~ '^\d{1,3}$' or p_value::int not between 7 and 365) then raise exception 'مدة الحفظ من ٧ لـ ٣٦٥ يوم'; end if;
  if length(p_value) > 300 then raise exception 'القيمة طويلة'; end if;
  insert into public.app_config (key, value) values (p_key, p_value)
  on conflict (key) do update set value = excluded.value;
  perform public.fn_admin_log('app_config', p_key, jsonb_build_object('value', p_value));
end $$;

-- الحساب اتمسح → سطوره في السجل بتفضل (للإحصائيات) بس من غير ما تتربط بيه
create or replace function public.trg_profile_logs_forget()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.app_logs set user_id = null, session_id = null where user_id = old.id;
  return old;
end $$;
drop trigger if exists profile_logs_forget on public.profiles;
create trigger profile_logs_forget before delete on public.profiles
for each row execute function public.trg_profile_logs_forget();

grant execute on function public.log_events(jsonb) to anon, authenticated;
grant execute on function public.admin_logs(text, text, int, bigint) to authenticated;
grant execute on function public.admin_log_stats() to authenticated;
grant execute on function public.fn_log(text, text, text, jsonb, text, text) to service_role;

