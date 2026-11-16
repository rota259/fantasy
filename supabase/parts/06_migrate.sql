-- الجزء 6 من 7 — شغّل الأجزاء بالترتيب (اتعمل من migrate_all.sql بـ tool/split_sql.py)
-- ═══ 51-ج. ديدلاين لكل لاعب + تغيير واحد ببلاش ═══
-- مفيش ديدلاين واحد للجولة تاني. الجولة زي ما هي (السبت ٤ العصر → السبت ٨ الصبح) وتشكيلة واحدة ليها، بس:
--   • كل لاعب بيتقفل لوحده قبل أول ماتش ليه في الجولة بساعة (fn_lock_at) — اللي اتقفل ميتشالش ولا يدخل
--     ولا يتغيّر مكانه (أساسي/احتياطي) ولا الكابتن يتنقل منه. اللي ماتشه لسه بعيد أو ملوش ماتش: حر.
--   • التغييرات = لاعيبة في تشكيلة الجولة مش موجودين في تشكيلة الجولة اللي قبلها. كل جولة بتاخد تغيير
--     ببلاش زيادة، واللي متستخدمش بيتجمّع للجولة الجاية (آخره ٥). كل تغيير فوق المجاني −٤ من نقط الجولة.
--     الوايلد كارد = كل تغييرات الجولة ببلاش (ومبياكلش من المتجمّع). أول تشكيلة في حياتك ببلاش.
--   • أول ما الجولة تبدأ (السبت ٨ الصبح) تشكيلة كل واحد بتتنقل لوحدها من الجولة اللي فاتت (fn_round_tick).
--   • أي ماتش يتضاف قبل ميعاده بساعتين على الأقل بيدخل الجولة على طول — من غير طلب ولا موافقة —
--     وأهل المنطقة بيوصلهم إشعار، وقبل الماتش بساعتين إشعار «لاعيبته بيتقفلوا بعد ساعة».
--   • الكروت (كلها، حتى الوايلد كارد): قبل ما أول لاعب في تشكيلتك يتقفل — بعدها مفيش كروت في الجولة دي.
--   • تشكيلات الناس: كل لاعب بيبان في تشكيلة صاحبها للناس أول ما يتقفل (مش قبل).
-- وضع التجربة: مفيش قفل خالص (زي الأول).

alter table public.matches add column if not exists created_at timestamptz not null default now();
alter table public.matches add column if not exists lock_reminded boolean not null default false;

-- «ديدلاين الجولة» بقى = بدايتها (السبت ٤ العصر) — بيستخدم بس للحاجات اللي محتاجة «الجولة بدأت»
-- (كسر التعادل · إشعار الكابتن · ظهور الكروت). القفل الحقيقي لكل لاعب في fn_lock_at.
create or replace function public.fn_round_deadline(p_round timestamptz)
returns timestamptz language sql immutable as $$
  select case when public.fn_test_mode() then p_round else public.fn_round_start(p_round) end;
$$;

-- الجولة اللي التشكيلة مفتوحة ليها = الجولة الحالية (وفي فاصل السبت: الجاية)
create or replace function public.fn_open_round()
returns timestamptz language sql stable as $$ select public.fn_week_cutoff(now()); $$;

-- الماتش مبقاش ليه ديدلاين جولة — شرطه الوحيد إنه يتعمل قبل ميعاده بساعتين (trg_matches_guard)
create or replace function public.fn_check_round_open(p_when timestamptz)
returns void language plpgsql stable as $$ begin null; end $$;

-- إمتى اللاعب بيتقفل في الجولة: قبل أول ماتش لفريقه فيها بساعة (null = ملوش ماتش · أو وضع التجربة)
create or replace function public.fn_lock_at(p_player uuid, p_round timestamptz)
returns timestamptz language sql stable set search_path = public as $$
  select case when public.fn_test_mode() then null else (
    select min(m.date_time) - public.fn_lock_lead()
    from public.matches m join public.players pl on pl.id = p_player
    where m.date_time > public.fn_round_from(p_round) and m.date_time <= p_round and m.review_status <> 'void'
      and lower(trim(pl.team)) in (lower(trim(m.teams[1])), lower(trim(m.teams[2])))) end;
$$;

-- اللاعب اتقفل؟ (أو الجولة نفسها خلصت)
create or replace function public.fn_player_locked(p_player uuid, p_round timestamptz)
returns boolean language sql stable set search_path = public as $$
  select not public.fn_test_mode() and (now() >= p_round or now() >= coalesce(public.fn_lock_at(p_player, p_round), 'infinity'));
$$;

-- عدد تغييرات كل يوزر في كل جولة (بيتحسب مع كل حفظ) — مفيش وصول مباشر
create table if not exists public.round_transfers (
  user_id   uuid references public.profiles(id) on delete cascade,
  round_end timestamptz not null,
  transfers int not null default 0,
  primary key (user_id, round_end)
);
alter table public.round_transfers add column if not exists free int not null default 1;   -- التغييرات المجانية في الجولة دي
alter table public.round_transfers enable row level security;

-- المجاني في جولة = (المجاني اللي فات − اللي اتصرف منه، ومش أقل من صفر) + ١ — وآخره ٥.
-- الوايلد كارد مبياكلش من المجاني. مفيش جولة قبلها = ١.
create or replace function public.fn_free_for(p_user uuid, p_round timestamptz)
returns int language sql stable security definer set search_path = public as $$
  select coalesce((
    select least(5, greatest(t.free - case when exists (select 1 from public.chip_uses c where c.user_id = p_user
                                                       and c.week_cutoff = t.round_end and c.chip = 'wildcard')
                                           then 0 else t.transfers end, 0) + 1)
    from public.round_transfers t where t.user_id = p_user and t.round_end < p_round
    order by t.round_end desc limit 1), 1);
$$;

-- خصم التغييرات: كل تغيير فوق المجاني −٤ (الوايلد كارد: صفر)
drop function if exists public.fn_transfer_cost(int, boolean);
create or replace function public.fn_transfer_cost(p_transfers int, p_wildcard boolean, p_free int)
returns int language sql immutable as $$
  select case when p_wildcard then 0 else 4 * greatest(coalesce(p_transfers, 0) - coalesce(p_free, 1), 0) end;
$$;

-- حفظ التشكيلة: نفس شروط التكوين + القفل لكل لاعب + عدّ التغييرات
create or replace function public.save_round_picks(p_round timestamptz, p_picks jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); z int; prev timestamptz; locked_name text;
        n_start int; n_bench int; n_gk int; n_cap int; n_vice int; n_bad int; n_dup int; n_zone int; n_mine int; max_team int;
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  perform public.fn_assert_active();
  if public.fn_is_zone_manager() then raise exception 'حساب المدير مش بيلعب فانتازي — اعمل حساب تاني لو عايز تلعب'; end if;
  if jsonb_typeof(p_picks) <> 'array' then raise exception 'بيانات غلط'; end if;
  if p_round is distinct from public.fn_open_round() then raise exception 'الجولة دي مش مفتوحة — حدّث الصفحة'; end if;
  perform pg_advisory_xact_lock(hashtext('picks:' || u::text));
  select zone_id into z from public.profiles where id = u;

  with sel as (
    select * from jsonb_to_recordset(p_picks) as x(player_id uuid, status text, is_captain boolean, is_vice boolean)
  ), j as (
    select s.player_id, s.status, coalesce(s.is_captain, false) as cap, coalesce(s.is_vice, false) as vic,
           pl.id as pid, pl.position, pl.zone_id, pl.team
    from sel s left join public.players pl on pl.id = s.player_id
  )
  select count(*) filter (where j.status = 'starting'),
         count(*) filter (where j.status = 'bench'),
         count(*) filter (where j.status = 'starting' and j.position = 'GK'),
         count(*) filter (where j.cap),
         count(*) filter (where j.vic),
         count(*) filter (where j.pid is null or j.status not in ('starting', 'bench')
                          or ((j.cap or j.vic) and j.status <> 'starting') or (j.cap and j.vic)),
         count(*) - count(distinct j.player_id),
         count(*) filter (where j.zone_id is not null and j.zone_id is distinct from z),
         count(*) filter (where exists (select 1 from public.teams t
                                        where lower(trim(t.name)) = lower(trim(j.team)) and t.owner_id = u))
  into n_start, n_bench, n_gk, n_cap, n_vice, n_bad, n_dup, n_zone, n_mine
  from j;

  if n_bad > 0 or n_dup > 0 then raise exception 'فيه لاعب غلط في التشكيلة — حدّث الصفحة'; end if;
  if n_zone > 0 then raise exception 'فيه لاعب مش من منطقتك'; end if;
  -- الكابتن يختار لاعيبة فريقه عادي · صاحب الملعب لأ (هو اللي بيسجّل أهداف ماتشات بطولته)
  if n_mine > 0 and public.is_venue_host() then
    raise exception 'صاحب الملعب ميختارش لاعيبة فرقه — هو اللي بيسجّل أهداف بطولته';
  end if;
  if n_start <> 5 then raise exception 'لازم ٥ أساسيين بالظبط'; end if;
  if n_bench <> 2 then raise exception 'لازم ٢ احتياطي'; end if;
  if n_gk <> 1 then raise exception 'لازم حارس واحد في الأساسيين'; end if;
  if n_cap <> 1 then raise exception 'اختار كابتن من الأساسيين'; end if;
  if n_vice <> 1 then raise exception 'اختار كابتن بديل من الأساسيين'; end if;
  -- ٣ لاعيبة بالكتير من نفس الفريق (لو فرق المنطقة قليلة الحد بيزيد عشان التشكيلة تكمل: فريقين = ٤).
  -- اللي كان عنده أكتر (في الجولة دي أو آخر جولة) مبيتعاقبش لحد ما يزوّد.
  max_team := greatest(3, ceil(7.0 / greatest(1, (select count(distinct lower(trim(pl.team))) from public.players pl
                                                  where pl.zone_id = z and trim(pl.team) <> ''))))::int;
  select coalesce(max(r.round_end), p_round) into prev from public.round_picks r where r.user_id = u and r.round_end <= p_round;
  if exists (
    select 1 from (
      select lower(trim(pl.team)) as tm, count(*) as n
      from jsonb_to_recordset(p_picks) as x(player_id uuid, status text, is_captain boolean, is_vice boolean)
      join public.players pl on pl.id = x.player_id group by 1) nw
    where nw.n > max_team and nw.n > (select count(*) from public.round_picks r join public.players pl on pl.id = r.player_id
                                      where r.user_id = u and r.round_end = prev and lower(trim(pl.team)) = nw.tm)) then
    raise exception 'آخرك % لاعيبة من نفس الفريق', max_team;
  end if;

  -- أي لاعب اتغيّر (دخل · خرج · مكانه · الكابتن) لازم يكون لسه متقفلش
  with old as (
    select player_id, status, is_captain, is_vice from public.round_picks where user_id = u and round_end = p_round
  ), new as (
    select player_id, status, coalesce(is_captain, false) as is_captain, coalesce(is_vice, false) as is_vice
    from jsonb_to_recordset(p_picks) as x(player_id uuid, status text, is_captain boolean, is_vice boolean)
  ), diff as (
    select coalesce(o.player_id, n.player_id) as player_id
    from old o full join new n on n.player_id = o.player_id
    where (o.status, o.is_captain, o.is_vice) is distinct from (n.status, n.is_captain, n.is_vice)
  )
  select pl.name into locked_name from diff join public.players pl on pl.id = diff.player_id
  where public.fn_player_locked(diff.player_id, p_round) limit 1;
  if locked_name is not null then
    raise exception '% اتقفل (ماتشه بدأ أو فاضل عليه أقل من ساعة) — مينفعش يتغيّر', locked_name;
  end if;

  delete from public.round_picks where user_id = u and round_end = p_round;
  insert into public.round_picks (user_id, round_end, player_id, status, is_captain, is_vice, saved_at)
  select u, p_round, x.player_id, x.status, coalesce(x.is_captain, false), coalesce(x.is_vice, false), now()
  from jsonb_to_recordset(p_picks) as x(player_id uuid, status text, is_captain boolean, is_vice boolean);

  -- التغييرات مقارنةً بتشكيلة آخر جولة قبلها (مفيش = أول تشكيلة = ببلاش)
  select max(round_end) into prev from public.round_picks where user_id = u and round_end < p_round;
  insert into public.round_transfers (user_id, round_end, transfers, free)
  values (u, p_round, case when prev is null then 0 else (
    select count(*) from public.round_picks n where n.user_id = u and n.round_end = p_round
      and not exists (select 1 from public.round_picks o where o.user_id = u and o.round_end = prev
                      and o.player_id = n.player_id)) end, public.fn_free_for(u, p_round))
  on conflict (user_id, round_end) do update set transfers = excluded.transfers;
  perform public.fn_recalc_user_round(u, p_round);
end $$;

-- (للشاشة) حالة الجولة لليوزر: قفل كل لاعب في منطقته · تشكيلة الجولة اللي فاتت (للعدّ) · الوايلد كارد
create or replace function public.my_round_state(p_round timestamptz)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare u uuid := auth.uid(); z int; prev timestamptz;
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  select zone_id into z from public.profiles where id = u;
  select max(round_end) into prev from public.round_picks where user_id = u and round_end < p_round;
  return jsonb_build_object(
    'locks', coalesce((select jsonb_object_agg(l.id, l.at) from (
                         select pl.id, public.fn_lock_at(pl.id, p_round) as at from public.players pl
                         where pl.zone_id = z) l where l.at is not null), '{}'::jsonb),
    'baseline', case when prev is null then null else
                  (select coalesce(jsonb_agg(player_id), '[]'::jsonb) from public.round_picks
                   where user_id = u and round_end = prev) end,
    'wildcard', exists (select 1 from public.chip_uses c where c.user_id = u and c.week_cutoff = p_round and c.chip = 'wildcard'),
    'transfers', coalesce((select transfers from public.round_transfers where user_id = u and round_end = p_round), 0),
    'free', coalesce((select free from public.round_transfers where user_id = u and round_end = p_round),
                     public.fn_free_for(u, p_round)),
    'hit', 4);
end $$;

-- تشكيلات الناس: كل لاعب بيبان أول ما يتقفل
drop policy if exists "round picks read" on public.round_picks;
create policy "round picks read" on public.round_picks for select to authenticated using (
  user_id = auth.uid() or public.is_manager() or public.fn_test_mode() or public.fn_player_locked(player_id, round_end)
);

-- الكروت (كلها): قبل ما أول لاعب في تشكيلتك يتقفل — لو حد فيهم ماتشه بدأ أو قرّب، مفيش كارت
create or replace function public.fn_chip_blocked(p_user uuid, p_round timestamptz, p_chip text)
returns text language sql stable security definer set search_path = public as $$
  select case
    when now() >= p_round and not public.fn_test_mode() then 'الجولة خلصت'
    when exists (select 1 from public.round_picks rp where rp.user_id = p_user
           and rp.round_end = p_round and public.fn_player_locked(rp.player_id, p_round))
      then 'لاعب في تشكيلتك اتقفل — الكارت لازم قبل أول ماتش ليك'
    end;
$$;

create or replace function public.activate_chip(p_round timestamptz, p_chip text)
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); st timestamptz := p_round; s public.seasons; h int; used int; why text;
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  perform public.fn_assert_active();
  if p_chip not in ('triple', 'bench_boost', 'wildcard', 'double') then raise exception 'كارت مش معروف'; end if;
  if public.fn_is_zone_manager() then raise exception 'حساب المدير مش بيلعب فانتازي'; end if;
  if p_round is distinct from public.fn_open_round() then raise exception 'الجولة دي مش مفتوحة'; end if;
  perform pg_advisory_xact_lock(hashtext(u::text));
  why := public.fn_chip_blocked(u, p_round, p_chip);
  if why is not null then raise exception '%', why; end if;
  perform public.fn_ensure_year(extract(year from p_round at time zone 'Africa/Cairo')::int);
  if not exists (select 1 from public.round_picks where user_id = u and round_end = p_round) then
    raise exception 'احفظ تشكيلتك للجولة دي الأول';
  end if;
  s := public.fn_season_at(st);
  if s.id is null then raise exception 'السنة لسه متجهّزتش — جرّب كمان دقيقة'; end if;
  h := case when st < s.mid_at then 1 else 2 end;
  if exists (select 1 from public.chip_uses where user_id = u and week_cutoff = p_round) then
    raise exception 'استخدمت كارت في الجولة دي — كارت واحد بس في الجولة';
  end if;
  if p_chip = 'double' then
    select count(*) into used from public.chip_uses where user_id = u and season_id = s.id and chip = 'double';
    if used >= public.fn_chip_limit(p_chip) then raise exception 'الدبل خلص — مرتين بس في السنة'; end if;
  else
    select count(*) into used from public.chip_uses where user_id = u and season_id = s.id and chip = p_chip and half = h;
    if used >= public.fn_chip_limit(p_chip) then
      raise exception '% خلص — مرتين بس في النص ده من السنة', public.fn_chip_name(p_chip);
    end if;
  end if;
  insert into public.chip_uses (user_id, chip, season_id, half, week_cutoff) values (u, p_chip, s.id, h, p_round);
  perform public.fn_recalc_user_round(u, p_round);
end $$;

create or replace function public.chip_status(p_round timestamptz)
returns table(chip text, used int, lim int, active boolean, blocked text)
language plpgsql stable security definer set search_path = public as $$
declare st timestamptz := p_round; s public.seasons; h int; here text; has_picks boolean;
begin
  s := public.fn_season_at(st);
  select c.chip into here from public.chip_uses c where c.user_id = auth.uid() and c.week_cutoff = p_round;
  has_picks := exists(select 1 from public.round_picks p where p.user_id = auth.uid() and p.round_end = p_round);
  if s.id is not null then h := case when st < s.mid_at then 1 else 2 end; end if;
  return query
  select k.chip,
    case when s.id is null then 0
         when k.chip = 'double' then (select count(*)::int from public.chip_uses c
              where c.user_id = auth.uid() and c.season_id = s.id and c.chip = 'double')
         else (select count(*)::int from public.chip_uses c
              where c.user_id = auth.uid() and c.season_id = s.id and c.chip = k.chip and c.half = h) end,
    public.fn_chip_limit(k.chip),
    coalesce(here = k.chip, false),
    case
      when here is not null then (case when here = k.chip then null else 'فعّلت ' || public.fn_chip_name(here) || ' في الجولة دي' end)
      when s.id is null then 'السنة لسه متجهّزتش'
      when not has_picks then 'احفظ تشكيلتك الأول'
      else public.fn_chip_blocked(auth.uid(), p_round, k.chip) end
  from (values ('triple'), ('bench_boost'), ('wildcard'), ('double')) as k(chip);
end $$;

-- نقط الجولة = (نفس الحسبة) − خصم التغييرات
create or replace function public.fn_round_points_bulk(p_round timestamptz, p_users uuid[])
returns table(user_id uuid, points int, final_points int)
language sql stable security definer set search_path = public as $$
  with ms as (
    select m.id, m.review_status = 'approved' as ok from public.matches m
    where m.date_time > public.fn_round_from(p_round) and m.date_time <= p_round and m.review_status <> 'void'
  ), pp as (
    select x.player_id, sum(x.points) as live,
      coalesce(sum(x.points) filter (where ms.ok), 0) as fin,
      bool_or(ms.ok) as played_fin
    from public.fn_pmp(public.fn_round_from(p_round), p_round) x join ms on ms.id = x.match_id
    group by x.player_id
  ), rp as (
    select rp.user_id, rp.status, rp.is_captain, rp.is_vice, coalesce(c.chip, '') as chip,
      coalesce(pp.live, 0) as live, coalesce(pp.fin, 0) as fin,
      pp.player_id is not null as played_live, coalesce(pp.played_fin, false) as played_fin
    from public.round_picks rp
    left join pp on pp.player_id = rp.player_id
    left join public.chip_uses c on c.user_id = rp.user_id and c.week_cutoff = p_round
    where rp.round_end = p_round and rp.user_id = any(p_users)
  ), cap as (
    select rp.user_id, bool_or(rp.is_captain and rp.played_live) as cap_live,
           bool_or(rp.is_captain and rp.played_fin) as cap_fin, max(rp.chip) as chip
    from rp group by rp.user_id
  ), cost as (
    select cap.user_id, public.fn_transfer_cost(t.transfers, cap.chip = 'wildcard', t.free) as c
    from cap left join public.round_transfers t on t.user_id = cap.user_id and t.round_end = p_round
  )
  select rp.user_id,
    ((coalesce(sum(rp.live * case
        when (rp.is_captain and cap.cap_live) or (rp.is_vice and not cap.cap_live)
          then case when rp.chip = 'triple' then 3 else 2 end else 1 end)
      filter (where rp.status = 'starting' or rp.chip = 'bench_boost'), 0)
      * case when max(rp.chip) = 'double' then 2 else 1 end) - max(cost.c))::int,
    ((coalesce(sum(rp.fin * case
        when (rp.is_captain and cap.cap_fin) or (rp.is_vice and not cap.cap_fin)
          then case when rp.chip = 'triple' then 3 else 2 end else 1 end)
      filter (where rp.status = 'starting' or rp.chip = 'bench_boost'), 0)
      * case when max(rp.chip) = 'double' then 2 else 1 end) - max(cost.c))::int
  from rp join cap on cap.user_id = rp.user_id join cost on cost.user_id = rp.user_id
  group by rp.user_id;
$$;


create or replace function public.remind_round(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  if not exists (select 1 from public.matches where id = p_match and status = 'upcoming') then
    raise exception 'الماتش مش موجود أو بدأ';
  end if;
  perform public.fn_notify_match(p_match, 'متنساش تشكيلتك ⏰',
    'كل لاعب بيتقفل قبل ماتشه بساعة — راجع لاعيبتك والكابتن', 'lineup');
end $$;

-- ماتش جديد/اتعدّل → إشعار لأهل المنطقة (وتقدر تختار من لاعيبته)
create or replace function public.trg_match_announce()
returns trigger language plpgsql security definer set search_path = public as $$
declare t text := to_char(new.date_time at time zone 'Africa/Cairo', 'DD/MM · HH12:MI');
begin
  if tg_op = 'INSERT' then
    perform public.fn_notify_match(new.id, 'ماتش جديد في منطقتك ⚽',
      new.teams[1] || ' ضد ' || new.teams[2] || ' · ' || t || ' — تقدر تختار من لاعيبته لحد قبل الماتش بساعة', 'match');
  elsif new.status = 'upcoming' and (new.date_time, new.teams) is distinct from (old.date_time, old.teams) then
    perform public.fn_notify_match(new.id, 'تعديل في ماتش 📝',
      new.teams[1] || ' ضد ' || new.teams[2] || ' · الميعاد الجديد ' || t, 'match');
  end if;
  return null;
end $$;

-- كل دقيقة (الوضع الحقيقي):
--   • أول الجولة: تشكيلة كل واحد بتتنقل من آخر جولة ليه (مرة لكل جولة)
--   • الجولة بدأت (السبت ٤ العصر)
--   • قبل كل ماتش بساعتين: «لاعيبته بيتقفلوا بعد ساعة» لأهل المنطقة (لو الماتش متعمل من بدري)
create or replace function public.fn_round_tick()
returns void language plpgsql security definer set search_path = public as $$
declare c timestamptz; st timestamptz; r record;
begin
  if public.fn_test_mode() then return; end if;
  c := public.fn_week_cutoff(now());

  insert into public.app_jobs (key) values ('carry:' || to_char(c at time zone 'UTC', 'YYYYMMDDHH24')) on conflict do nothing;
  if found then
    insert into public.round_picks (user_id, round_end, player_id, status, is_captain, is_vice, saved_at)
    select rp.user_id, c, rp.player_id, rp.status, rp.is_captain, rp.is_vice, now()
    from public.round_picks rp
    where rp.round_end = (select max(x.round_end) from public.round_picks x where x.user_id = rp.user_id and x.round_end < c)
      and not exists (select 1 from public.round_picks y where y.user_id = rp.user_id and y.round_end = c);
    -- المجاني المتجمّع للجولة الجديدة
    insert into public.round_transfers (user_id, round_end, transfers, free)
    select u.user_id, c, 0, public.fn_free_for(u.user_id, c)
    from (select distinct user_id from public.round_picks where round_end = c) u
    on conflict (user_id, round_end) do nothing;
    perform public.fn_log('info', 'job.round.carry', null, jsonb_build_object('round', c));
  end if;

  st := public.fn_round_start(c);
  if now() >= st and now() < st + interval '1 hour' then
    insert into public.app_jobs (key) values ('round_start:' || to_char(c at time zone 'UTC', 'YYYYMMDDHH24')) on conflict do nothing;
    if found then
      insert into public.notifications (title, body, kind, audience, sound, link)
      values ('🟢 الجولة بدأت', 'كل لاعب بيتقفل قبل ماتشه بساعة — وعندك تغيير واحد ببلاش', 'match', 'all', 'round', 'team');
    end if;
  end if;

  for r in update public.matches m set lock_reminded = true
           where m.status = 'upcoming' and not m.lock_reminded and m.zone_id is not null
             and now() >= m.date_time - interval '2 hours' and now() < m.date_time - public.fn_lock_lead()
           returning m.id, m.teams, m.created_at, m.date_time, m.zone_id loop
    if r.created_at < r.date_time - interval '2 hours 15 minutes' then   -- لو لسه متعمل، إشعار «ماتش جديد» كفاية
      insert into public.notifications (title, body, kind, match_id, audience, zone_id, sound, link)
      values ('⏳ ' || r.teams[1] || ' ضد ' || r.teams[2] || ' كمان ساعتين',
              'لاعيبته بيتقفلوا في تشكيلتك بعد ساعة — آخر فرصة تدخّلهم أو تخلّي حد منهم كابتن',
              'lineup', r.id, 'zone', r.zone_id, 'deadline', 'team');
    end if;
  end loop;
end $$;

grant execute on function public.my_round_state(timestamptz) to authenticated;

-- ═══ 51-د. السنة بدل الموسم ═══
-- مفيش مواسم الأدمن بيعملها: كل سنة ميلادي = «موسم» لوحدها، بتتعمل أوتوماتيك (fn_ensure_year).
--   • من أول يناير ١٢ بالليل (القاهرة) لأول يناير اللي بعده — ونصها (للكروت) أول يوليو.
--   • الجولة بتتبع السنة اللي بتخلص فيها (الجولة اللي بتخلص السبت ٢ يناير = أول جولة في السنة الجديدة).
--   • الدوري العام بيتصفّر أول كل سنة + إشعار للكل.
--   • الكروت: كابتن ×٣ · الاحتياطي يتحسب · الوايلد كارد مرتين في كل نص سنة، والدبل مرتين في السنة.
-- الجدول seasons فاضل زي ما هو (الدوال كلها بتقرا منه)، بس صفوفه بقت سنين بس — ومحدش يكتب فيه من الأبلكيشن.
alter table public.seasons add column if not exists year int;
create unique index if not exists seasons_year on public.seasons(year) where year is not null;
drop policy if exists "seasons manager write" on public.seasons;

create or replace function public.fn_ensure_year(p_year int)
returns void language sql security definer set search_path = public as $$
  insert into public.seasons (name, starts_at, mid_at, ends_at, year)
  select 'سنة ' || p_year, make_timestamptz(p_year, 1, 1, 0, 0, 0, 'Africa/Cairo'),
         make_timestamptz(p_year, 7, 1, 0, 0, 0, 'Africa/Cairo'), make_timestamptz(p_year + 1, 1, 1, 0, 0, 0, 'Africa/Cairo'), p_year
  where not exists (select 1 from public.seasons where year = p_year);
$$;

-- السنة الحالية واللي بعدها موجودين دايمًا · الكروت القديمة بتتنقل لسنتها · المواسم القديمة بتتشال
do $$
declare y int;
begin
  for y in select distinct extract(year from x at time zone 'Africa/Cairo')::int from (
             select now() as x union all select now() + interval '1 year'
             union all select week_cutoff from public.chip_uses
             union all select public.fn_week_cutoff(now()) where public.fn_test_mode()) t loop
    perform public.fn_ensure_year(y);
  end loop;
  update public.chip_uses c set season_id = s.id, half = case when c.week_cutoff < s.mid_at then 1 else 2 end
  from public.seasons s
  where s.year = extract(year from c.week_cutoff at time zone 'Africa/Cairo')::int and c.season_id is distinct from s.id;
  delete from public.seasons where year is null;
end $$;

-- كل دقيقة: السنة الجديدة بتبدأ لوحدها → الدوري يتصفّر + إشعار (مرة واحدة لكل سنة)
create or replace function public.fn_season_tick()
returns void language plpgsql security definer set search_path = public as $$
declare s public.seasons; y int := extract(year from now() at time zone 'Africa/Cairo')::int;
begin
  perform public.fn_ensure_year(y);
  perform public.fn_ensure_year(y + 1);
  if public.fn_test_mode() then return; end if;
  s := public.fn_season_at(now());
  if s.id is null then return; end if;
  insert into public.app_jobs (key) values ('season_start:' || s.id) on conflict do nothing;
  if not found then return; end if;
  perform public.fn_recalc_all_totals();
  insert into public.notifications (title, body, kind, audience)
  values ('🏁 سنة جديدة بدأت: ' || s.year, 'الدوري العام اتصفّر والكل بيبدأ من الأول — والكروت رجعت كاملة', 'match', 'all');
end $$;

-- (أدمن) هدف/تصدّي السنة: المرشّحين = كل اللي كسبوا هدف/تصدّي الجولة في السنة دي
create or replace function public.create_season_award(p_kind text)
returns uuid language plpgsql security definer set search_path = public as $$
declare s public.seasons; pid uuid; n int;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  if p_kind not in ('goal', 'save') then raise exception 'نوع غلط'; end if;
  perform public.fn_ensure_year(extract(year from now() at time zone 'Africa/Cairo')::int);
  s := public.fn_season_at(now());
  update public.polls set active = false where kind = p_kind || '_season' and active;
  insert into public.polls (kind, question, active)
  values (p_kind || '_season', case when p_kind = 'goal' then 'هدف السنة 🏆' else 'تصدّي السنة 🏆' end, true)
  returning id into pid;
  insert into public.poll_options (poll_id, label, player_id, video_url, match_id)
  select pid, o.label, o.player_id, o.video_url, o.match_id
  from public.polls p join public.poll_options o on o.id = public.fn_poll_winner(p.id)
  where p.kind = p_kind || '_week' and not p.active
    and p.created_at >= s.starts_at and p.created_at < s.ends_at;
  get diagnostics n = row_count;
  if n < 2 then raise exception 'محتاج فايزين اتنين على الأقل من جولات السنة دي'; end if;
  insert into public.notifications (title, body, kind)
  values (case when p_kind = 'goal' then '🏆 تصويت هدف السنة' else '🏆 تصويت تصدّي السنة' end,
          'اتفرّج على أحلى ' || n || ' واختار الأحسن', 'vote');
  return pid;
end $$;

-- ═══ 51-هـ. إشعار تجربة لأي يوزر (من شاشة «الإشعارات على موبايلك») ═══
create or replace function public.send_my_test_push()
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid();
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  perform public.fn_assert_active();
  if exists (select 1 from public.notifications where user_id = u and title = '🔔 تجربة الإشعارات'
             and created_at > now() - interval '1 minute') then
    raise exception 'استنى دقيقة قبل تجربة تانية';
  end if;
  insert into public.notifications (title, body, kind, user_id, sound, link)
  values ('🔔 تجربة الإشعارات', 'لو شايف ده فوق الشاشة وسامع صوته والأبلكيشن مقفول يبقى كله تمام ✓', 'match', u, 'goal', 'account');
end $$;
grant execute on function public.send_my_test_push() to authenticated;

-- ═══ 51-و. تشكيلة الجولة ونجمها لايف من الماتشات المعتمدة ═══
-- مفيش استنّا لآخر الجولة ولا اعتماد أدمن: أول ما نتيجة ماتش تتعتمد، نقط لاعيبته بتدخل الحساب،
-- واللي جاب أعلى من حد في التشكيلة بياخد مكانه (الحارس الأعلى + أعلى ٤). نفس player_points_between
-- بس من الماتشات المعتمدة بس (وفي وضع التجربة: كل الماتشات اللي مش ملغية).
create or replace function public.player_points_approved(p_from timestamptz, p_to timestamptz, p_zone int default null)
returns table(id uuid, name text, team text, "position" text, points bigint, image_url text, verified boolean)
language sql stable security definer set search_path = public as $$
  select pl.id, pl.name, pl.team, pl.position,
    sum(x.points)::bigint as points,
    coalesce(pl.image_url, (select pr.photo_url from public.profiles pr where pr.id = pl.user_id)),
    pl.user_id is not null
  from public.fn_pmp(p_from, p_to) x
  join public.matches m on m.id = x.match_id
    and (p_zone is null or m.zone_id = p_zone)
    and (m.review_status = 'approved' or public.fn_test_mode())
  join public.players pl on pl.id = x.player_id
  group by pl.id, pl.name, pl.team, pl.position, pl.image_url, pl.user_id
  having sum(x.points) <> 0
  order by points desc, pl.name;
$$;
grant execute on function public.player_points_approved(timestamptz, timestamptz, int) to authenticated;

-- الماتشات اللي خلصت قبل ما المهلة تبقى ٤ ساعات (كانت ١٢): ميعاد اعتمادها يتظبط على الجديدة،
-- واللي مهلته عدّت ومحدش اعترض يتعتمد دلوقتي على طول
update public.matches
set review_due = coalesce(finished_at, review_due - interval '12 hours') + public.fn_review_window()
where review_status = 'pending' and review_due is not null
  and review_due > coalesce(finished_at, review_due - interval '12 hours') + public.fn_review_window();

-- الاعتماد التلقائي: أي ماتش مستني ومهلته (٤ ساعات) عدّت ومحدش من الفريقين اعترض → يتعتمد.
-- (الاعتراض بيخلّي الماتش «disputed» فمبيدخلش هنا — ده بس اللي بيستنى الأدمن.)
-- العلامات الأوتوماتيك (مدير جديد · فرق أهداف كبير · المدير جايب أهداف لنفسه · تعديل بعد النهاية) مبقتش بتوقّف
-- الاعتماد — كانت بتعلّق كل ماتشات المديرين الجداد للأبد (علامة «مدير جديد» مبتتشالش غير بعد ٥ ماتشات معتمدة).
-- بدالها: الأدمنز بيوصلهم إشعار يراجعوه، ويقدروا يلغوه من «مراجعة الماتشات» لو فيه غش.
create or replace function public.fn_review_tick()
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in update public.matches set review_status = 'approved', review_due = null
           where review_status = 'pending' and review_due <= now()
           returning id, teams, flags loop
    if cardinality(r.flags) > 0 and r.flags <> array['new_organizer'] then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🔎 ماتش اتعتمد لوحده وعليه علامات', r.teams[1] || ' ضد ' || r.teams[2] || ' — راجعه، ولو فيه غش الغيه',
             'review', p.id, r.id
      from public.profiles p where p.role = 'manager';
    end if;
  end loop;
end $$;
select public.fn_review_tick();

-- كل دقيقة (مش كل ١٠): الماتش يتعتمد في نفس الدقيقة اللي مهلته بتخلص فيها → تشكيلة الجولة تتحدّث على طول
create or replace function public.fn_close_due_matches_and_season()
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_match_start_tick();
  perform public.fn_close_due_matches();
  perform public.fn_review_tick();
  perform public.fn_season_tick();
  perform public.fn_round_tick();
end $$;

-- ═══ 51-ز. نزاهة الماتشات: كابتن الخصم بيأكّد · سقف نقط للماتش · مصداقية المدير ═══
-- المشكلة: مدير واحد بيدخّل كل حاجة، ومعظم اللاعيبة معندهمش الأبلكيشن — فمحدش مستقل يقدر يكشف نتيجة مضروبة.
-- ١) كل فريق ليه كابتن (صاحب الفريق في "فرقي"). الماتش ممكن يبقى بين فريقي وفريق كابتن تاني:
--    الكابتن التاني بيوصله إشعار أول ما الماتش يتعمل، وبعد النهاية تأكيده = اعتماد فوري، واعتراضه = الإدارة تحكم.
-- ٣) سقف للاعب في الماتش الواحد: الأهداف بعد الخامس والأسيستات بعد الخامس مبتتحسبش، والمجموع مايعدّيش ٢٥.
-- ٤) مصداقية: المدير الجديد (أقل من ٥ ماتشات معتمدة) أو اللي عليه إنذار — ماتشه مبيتعتمدش لوحده بعد ٤ ساعات،
--    لازم تأكيد كابتن الخصم أو الأدمن. كل ماتش الإدارة تلغيه = إنذار، والتالت = إيقاف + كل ماتشاته تتلغي (نقطها تروح).
alter table public.profiles add column if not exists strikes int not null default 0;
alter table public.matches add column if not exists opp_captain uuid references public.profiles(id) on delete set null;

-- فريق واحد على الأقل لازم يكون بتاعي، والتاني يا إما بتاعي يا إما فريق موجود ليه كابتن
create or replace function public.fn_check_my_teams(p_teams text[])
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if not exists (select 1 from public.teams t where t.owner_id = auth.uid()
                 and lower(trim(t.name)) in (lower(trim(p_teams[1])), lower(trim(p_teams[2])))) then
    raise exception 'لازم فريق من الاتنين يكون من فرقك — ضيفه من "فرقي"';
  end if;
  if (select count(*) from public.teams t
      where lower(trim(t.name)) in (lower(trim(p_teams[1])), lower(trim(p_teams[2])))
        and t.owner_id is not null) < 2 then
    raise exception 'فريق الخصم لازم يكون مسجّل وليه كابتن على الأبلكيشن';
  end if;
end $$;

-- كابتن الخصم = صاحب الفريق اللي مش بتاع المدير (null = المدير صاحب الفريقين)
create or replace function public.fn_opp_captain(p_teams text[], p_org uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select t.owner_id from public.teams t
  where lower(trim(t.name)) in (lower(trim(p_teams[1])), lower(trim(p_teams[2])))
    and t.owner_id is not null and t.owner_id is distinct from p_org
  limit 1;
$$;

create or replace function public.trg_match_opp()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.teams is distinct from old.teams or new.organizer_id is distinct from old.organizer_id then
    new.opp_captain := public.fn_opp_captain(new.teams, new.organizer_id);
  else
    new.opp_captain := old.opp_captain;
  end if;
  return new;
end $$;
drop trigger if exists matches_opp on public.matches;   -- بعد matches_guard (الترتيب بالاسم)
create trigger matches_opp before insert or update on public.matches
for each row execute function public.trg_match_opp();

create or replace function public.trg_match_opp_notify()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.opp_captain is not null and (tg_op = 'INSERT' or new.opp_captain is distinct from old.opp_captain) then
    insert into public.notifications (title, body, kind, user_id, match_id)
    values ('🤝 ماتش ضد فريقك', new.teams[1] || ' ضد ' || new.teams[2] || ' — لو الماتش ده مش متفق عليه، اعترض بعد ما يخلص',
            'review', new.opp_captain, new.id);
  end if;
  return null;
end $$;
drop trigger if exists matches_opp_notify on public.matches;
create trigger matches_opp_notify after insert or update of teams on public.matches
for each row execute function public.trg_match_opp_notify();

-- الكابتن التاني بيراجع باسم فريقه (حتى لو هو مدير)، وغيره زي الأول: لاعب موثّق في التشكيلة
create or replace function public.fn_reviewer_team(p_match uuid, p_user uuid)
returns text language sql stable security definer set search_path = public as $$
  select coalesce(
    (select t.name from public.matches m join public.teams t
       on lower(trim(t.name)) in (lower(trim(m.teams[1])), lower(trim(m.teams[2]))) and t.owner_id = p_user
     where m.id = p_match and m.opp_captain = p_user limit 1),
    (select pl.team from public.lineups l
       join public.players pl on pl.id = l.player_id
       join public.matches m on m.id = l.match_id
     where l.match_id = p_match and pl.user_id = p_user and m.organizer_id is distinct from p_user
       and not exists (select 1 from public.profiles pr where pr.id = p_user and pr.role = 'organizer')
     limit 1));
$$;

create or replace function public.fn_ask_reviewers(p_match uuid)
returns void language sql security definer set search_path = public as $$
  insert into public.notifications (title, body, kind, user_id, match_id)
  select distinct on (x.uid) x.title,
         m.teams[1] || ' ' || m.score_a || ' - ' || m.score_b || ' ' || m.teams[2] || ' — النتيجة والأهداف صح؟',
         'review', x.uid, m.id
  from public.matches m
  cross join lateral (
    select m.opp_captain as uid, '🧢 أكّد نتيجة ماتشك (إنت كابتن الخصم)' as title where m.opp_captain is not null
    union all
    select pl.user_id, '📋 أكّد ورقة الماتش' from public.lineups l join public.players pl on pl.id = l.player_id
    where l.match_id = m.id and pl.user_id is not null and pl.user_id is distinct from m.organizer_id
  ) x
  where m.id = p_match
  order by x.uid, x.title desc;
$$;

-- تأكيد كابتن الخصم لوحده كفاية
create or replace function public.trg_review_captain()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.ok then
    update public.matches set review_status = 'approved', review_due = null
    where id = new.match_id and opp_captain = new.user_id and review_status = 'pending';
  end if;
  return null;
end $$;
drop trigger if exists review_captain on public.match_reviews;
create trigger review_captain after insert or update on public.match_reviews
for each row execute function public.trg_review_captain();

-- موثوق = ٥ ماتشات معتمدة على الأقل ومن غير إنذارات
create or replace function public.fn_trusted(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select strikes = 0 from public.profiles where id = p_org), false)
     and (select count(*) from public.matches where organizer_id = p_org and review_status = 'approved') >= 5;
$$;

-- الاعتماد بالسكوت بعد ٤ ساعات: للموثوق بس. الجديد → الأدمن بيوصله إشعار مرة واحدة يعتمده أو يلغيه
create or replace function public.fn_review_tick()
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in update public.matches m set review_status = 'approved', review_due = null
           where m.review_status = 'pending' and m.review_due <= now()
             and (m.organizer_id is null or public.fn_trusted(m.organizer_id))
           returning m.id, m.teams, m.flags loop
    if cardinality(r.flags) > 0 and r.flags <> array['new_organizer'] then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🔎 ماتش اتعتمد لوحده وعليه علامات', r.teams[1] || ' ضد ' || r.teams[2] || ' — راجعه، ولو فيه غش الغيه',
             'review', p.id, r.id
      from public.profiles p where p.role = 'manager';
    end if;
  end loop;
  for r in select m.id, m.teams, m.opp_captain from public.matches m
           where m.review_status = 'pending' and m.review_due <= now() loop
    insert into public.app_jobs (key) values ('review-nudge:' || r.id) on conflict do nothing;
    if found then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🔎 ماتش مدير جديد مستني اعتمادك', r.teams[1] || ' ضد ' || r.teams[2]
               || case when r.opp_captain is null then ' — المدير صاحب الفريقين' else ' — كابتن الخصم مأكّدش' end,
             'review', p.id, r.id
      from public.profiles p where p.role = 'manager';
    end if;
  end loop;
end $$;

-- الإدارة لغت ماتش → إنذار للمدير. التالت = إيقاف + كل ماتشاته تتلغي
create or replace function public.trg_match_strike()
returns trigger language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if pg_trigger_depth() > 1 or new.organizer_id is null then return null; end if;
  if new.review_status = 'void' and old.review_status is distinct from 'void' then
    update public.profiles set strikes = strikes + 1 where id = new.organizer_id and role <> 'manager'
    returning strikes into n;
    if n is null then return null; end if;
    if n >= 3 then
      update public.profiles set is_active = false where id = new.organizer_id;
      delete from public.events e using public.matches m
      where e.match_id = m.id and m.organizer_id = new.organizer_id and m.id <> new.id;
      update public.matches set review_status = 'void', review_due = null
      where organizer_id = new.organizer_id and id <> new.id and status = 'finished';
      perform public.fn_admin_log('organizer_banned', new.organizer_id::text, jsonb_build_object('strikes', n));
    end if;
    insert into public.notifications (title, body, kind, user_id, match_id)
    values (case when n >= 3 then '⛔ حسابك اتوقف' else '⚠️ إنذار ' || n || ' من ٣' end,
            case when n >= 3 then '٣ ماتشات اتلغت بسبب غش — كل ماتشاتك اتلغت ونقطها راحت'
                 else 'الإدارة لغت ماتش ' || new.teams[1] || ' ضد ' || new.teams[2] || ' — الإنذار التالت = إيقاف' end,
            'review', new.organizer_id, new.id);
  end if;
  return null;
end $$;
drop trigger if exists match_strike on public.matches;
create trigger match_strike after update of review_status on public.matches
for each row execute function public.trg_match_strike();

-- المصداقية (باينة للكل): معتمد · ملغي · إنذارات · موثوق · نسبة
create or replace function public.organizer_trust(p_user uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  with c as (
    select count(*) filter (where review_status = 'approved') as ok,
           count(*) filter (where review_status = 'void') as bad
    from public.matches where organizer_id = p_user and status = 'finished')
  select jsonb_build_object('approved', c.ok, 'voided', c.bad,
    'strikes', coalesce((select strikes from public.profiles where id = p_user), 0),
    'trusted', public.fn_trusted(p_user),
    'score', case when c.ok + c.bad = 0 then null else round(100.0 * c.ok / (c.ok + c.bad)) end)
  from c;
$$;
grant execute on function public.organizer_trust(uuid) to authenticated;

-- ٣) سقف النقط: ٥ أهداف و٥ أسيست بالكتير بيتحسبوا، والمجموع لحد ٢٥
create or replace function public.fn_score_raw(p_pos text, g int, a int, sv int, ps int, pm int,
                                               tk int, ins int, og int, motm int, cs boolean,
                                               yc int, rc int, st boolean)
returns int language sql immutable as $$
  select (case when p_pos = 'GK' then least(g, 5) * 8 else least(g, 3) * 5 + greatest(least(g, 5) - 3, 0) * 7 end)
       + case when g >= 3 then 6 else 0 end
       + least(a, 3) * 3 + greatest(least(a, 5) - 3, 0) * 5 + case when a >= 3 then 4 else 0 end
       + sv / 3 + ps * 4 + case when cs then 8 else 0 end + case when st then 3 else 0 end
       + tk / 5 - pm * 3 - ins * 5 - og * 2 + motm * 3 - yc - rc * 2;
$$;
create or replace function public.fn_score_points(p_pos text, g int, a int, sv int, ps int, pm int,
                                                  tk int, ins int, og int, motm int, cs boolean,
                                                  yc int default 0, rc int default 0, st boolean default false)
returns int language sql immutable as $$
  select least(public.fn_score_raw(p_pos, g, a, sv, ps, pm, tk, ins, og, motm, cs, yc, rc, st), 25);
$$;
create or replace function public.fn_score_items(p_pos text, g int, a int, sv int, ps int, pm int,
                                                 tk int, ins int, og int, motm int, cs boolean,
                                                 yc int default 0, rc int default 0, st boolean default false)
returns jsonb language sql immutable as $$
  with r as (select public.fn_score_raw(p_pos, g, a, sv, ps, pm, tk, ins, og, motm, cs, yc, rc, st) as raw)
  select coalesce(jsonb_agg(jsonb_build_object('k', k, 'n', n, 'p', pts)) filter (where n > 0), '[]'::jsonb)
  from r, (values
    ('مشاركة (أساسي)', case when st then 1 else 0 end, 3),
    ('جول', g, case when p_pos = 'GK' then least(g, 5) * 8 else least(g, 3) * 5 + greatest(least(g, 5) - 3, 0) * 7 end),
    ('بونص هاتريك أهداف', case when g >= 3 then 1 else 0 end, 6),
    ('أسيست', a, least(a, 3) * 3 + greatest(least(a, 5) - 3, 0) * 5),
    ('بونص هاتريك أسيست', case when a >= 3 then 1 else 0 end, 4),
    ('تصديات', sv, sv / 3),
    ('صد بلنتي', ps, ps * 4),
    ('كلين شيت', case when cs then 1 else 0 end, 8),
    ('تدخلات دفاعية', tk, tk / 5),
    ('ضيّع بلنتي', pm, -3 * pm),
    ('سب', ins, -5 * ins),
    ('جول عكسي', og, -2 * og),
    ('رجل المباراة', motm, 3 * motm),
    ('كارت أصفر', yc, -yc),
    ('كارت أحمر', rc, -2 * rc),
    ('سقف الماتش (٢٥ نقطة)', case when (select raw from r) > 25 then 1 else 0 end, 25 - (select raw from r))
  ) x(k, n, pts);
$$;

do $$
begin
  if not exists (select 1 from public.app_jobs where key = 'points_cap_recalc') then
    perform public.fn_recalc_player(id) from public.players;
    perform public.fn_recalc_users();
    insert into public.app_jobs (key) values ('points_cap_recalc') on conflict do nothing;
  end if;
end $$;

-- ═══ 51-ح. الأسامي المتشابهة: اسم الشهرة + تمييز أوتوماتيك + تحذير قبل التكرار ═══
-- كل لاعب سجل لوحده (id) فالنقط عمرها ما بتتلخبط — المشكلة في العرض بس:
--   nickname  اسم الشهرة اللي المنطقة عارفاه («حمو») — اختياري، بيظهر جنب الاسم
--   name_dup  (السيرفر بس) فيه لاعب تاني في نفس المنطقة أول اسمه زيّه → الأبلكيشن يكتب الفريق جنبه
alter table public.players add column if not exists nickname text;
alter table public.players add column if not exists name_dup boolean not null default false;
do $$ begin
  alter table public.players add constraint players_nickname_len check (nickname is null or length(trim(nickname)) between 1 and 20);
exception when duplicate_object then null; end $$;

create or replace function public.fn_first_name(p text)
returns text language sql immutable as $$ select split_part(lower(regexp_replace(trim(p), '\s+', ' ', 'g')), ' ', 1); $$;

create or replace function public.fn_refresh_dups(p_zone int)
returns void language sql security definer set search_path = public as $$
  update public.players p set name_dup = x.d
  from (select id, count(*) over (partition by public.fn_first_name(name)) > 1 as d
        from public.players where zone_id is not distinct from p_zone) x
  where p.id = x.id and p.name_dup is distinct from x.d;
$$;

create or replace function public.trg_players_dups()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op <> 'INSERT' then perform public.fn_refresh_dups(old.zone_id); end if;
  if tg_op <> 'DELETE' and (tg_op = 'INSERT' or new.zone_id is distinct from old.zone_id
     or new.name is distinct from old.name) then
    perform public.fn_refresh_dups(new.zone_id);
  end if;
  return null;
end $$;
drop trigger if exists players_dups on public.players;
create trigger players_dups after insert or delete or update of name, zone_id on public.players
for each row execute function public.trg_players_dups();

-- العميل ميقدرش يكتب name_dup بإيده
create or replace function public.trg_players_dup_guard()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.name_dup := case when tg_op = 'INSERT' then false else old.name_dup end;
  end if;
  new.nickname := nullif(trim(new.nickname), '');
  return new;
end $$;
drop trigger if exists players_dup_guard on public.players;
create trigger players_dup_guard before insert or update on public.players
for each row execute function public.trg_players_dup_guard();

do $$
declare z int;
begin
  if not exists (select 1 from public.app_jobs where key = 'name_dups_v1') then
    for z in select distinct zone_id from public.players loop perform public.fn_refresh_dups(z); end loop;
    perform public.fn_refresh_dups(null);
    insert into public.app_jobs (key) values ('name_dups_v1') on conflict do nothing;
  end if;
end $$;

-- قبل ما المدير يضيف لاعب: لاعيبة في منطقة الفريق اسمهم نفس الاسم كامل أو نفس أول اسمين
create or replace function public.similar_players(p_name text, p_team text)
returns table(id uuid, name text, nickname text, team text, verified boolean)
language sql stable security definer set search_path = public as $$
  with n as (select lower(regexp_replace(trim(p_name), '\s+', ' ', 'g')) as s),
  z as (select public.fn_team_zone(p_team) as zone)
  select p.id, p.name, p.nickname, p.team, p.user_id is not null
  from public.players p, n, z
  where p.zone_id is not distinct from z.zone and auth.uid() is not null
    and (lower(regexp_replace(trim(p.name), '\s+', ' ', 'g')) = n.s
         or (position(' ' in n.s) > 0 and split_part(lower(regexp_replace(trim(p.name), '\s+', ' ', 'g')), ' ', 1)
               || ' ' || split_part(lower(regexp_replace(trim(p.name), '\s+', ' ', 'g')), ' ', 2)
             = split_part(n.s, ' ', 1) || ' ' || split_part(n.s, ' ', 2)))
  order by p.team = p_team desc, p.name
  limit 10;
$$;
grant execute on function public.similar_players(text, text) to authenticated;

-- ═══ 51-ط. كابتن مشبوه + مشرف منطقة ═══
-- كابتن مشبوه: المدير ممكن يعمل حساب تاني ويخلّيه «كابتن الخصم» ويأكّد لنفسه. تأكيد الكابتن مبيعتمدش لوحده لو:
--   fresh_captain  حساب الكابتن عمره أقل من ٧ أيام
--   closed_pair    آخر ٣ ماتشات (أو أكتر) للمدير كلها ضد نفس الكابتن ده بس
-- الماتش ساعتها بيستنى الأدمن/المشرف، ومبيتعتمدش بالسكوت حتى لو المدير موثوق.
alter table public.profiles add column if not exists supervisor_zone int references public.zones(id) on delete set null;

create or replace function public.fn_captain_flags(p_match uuid)
returns text[] language sql stable security definer set search_path = public as $$
  with m as (select * from public.matches where id = p_match)
  select array_remove(array[
    case when (select created_at > now() - interval '7 days' from public.profiles where id = m.opp_captain)
         then 'fresh_captain' end,
    case when (select count(*) >= 3 and bool_and(x.opp_captain is not distinct from m.opp_captain)
               from (select opp_captain from public.matches
                     where organizer_id = m.organizer_id and status = 'finished' and review_status <> 'void'
                     order by date_time desc limit 5) x)
         then 'closed_pair' end
  ], null)
  from m where m.opp_captain is not null;
$$;

create or replace function public.trg_review_captain()
returns trigger language plpgsql security definer set search_path = public as $$
declare m public.matches; f text[];
begin
  if not new.ok then return null; end if;
  select * into m from public.matches where id = new.match_id;
  if m.opp_captain is distinct from new.user_id or m.review_status <> 'pending' then return null; end if;
  f := coalesce(public.fn_captain_flags(m.id), '{}');
  if cardinality(f) = 0 then
    update public.matches set review_status = 'approved', review_due = null where id = m.id;
  else
    update public.matches set flags = array(select distinct unnest(m.flags || f)) where id = m.id;
    insert into public.notifications (title, body, kind, user_id, match_id)
    select '🕵️ تأكيد كابتن محتاج نظرة', m.teams[1] || ' ضد ' || m.teams[2] || ' — '
             || case when 'closed_pair' = any(f) then 'المدير بيلعب دايمًا ضد نفس الكابتن' else 'حساب الكابتن جديد' end,
           'review', p.id, m.id
    from public.profiles p
    where p.role = 'manager' or (p.supervisor_zone = m.zone_id and p.id is distinct from m.organizer_id
                                 and p.id is distinct from m.opp_captain);
  end if;
  return null;
end $$;

-- مشرف المنطقة: الأدمن بيعيّنه، وبيعتمد/يلغي ماتشات منطقته (مش ماتشاته هو) — عشان الأدمن ميبقاش عنق زجاجة
create or replace function public.fn_can_judge(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_manager() or exists (
    select 1 from public.matches m join public.profiles p on p.id = auth.uid()
    where m.id = p_match and p.supervisor_zone = m.zone_id and p.is_active
      and auth.uid() is distinct from m.organizer_id and auth.uid() is distinct from m.opp_captain);
$$;

create or replace function public.am_supervisor()
returns int language sql stable security definer set search_path = public as $$
  select supervisor_zone from public.profiles where id = auth.uid() and is_active;
$$;
grant execute on function public.am_supervisor() to authenticated;

create or replace function public.set_supervisor(p_user uuid, p_zone int)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  update public.profiles set supervisor_zone = p_zone where id = p_user;
  perform public.fn_admin_log('set_supervisor', p_user::text, jsonb_build_object('zone', p_zone));
  if p_zone is not null then
    insert into public.notifications (title, body, kind, user_id)
    values ('🛡️ بقيت مشرف منطقة', 'تقدر تعتمد أو تلغي ماتشات منطقتك من «مراجعة الماتشات»', 'review', p_user);
  end if;
end $$;
grant execute on function public.set_supervisor(uuid, int) to authenticated;

create or replace function public.resolve_match(p_match uuid, p_action text)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  if not public.fn_can_judge(p_match) then raise exception 'للأدمن أو مشرف المنطقة بس'; end if;
  select * into m from public.matches where id = p_match;
  if not found or m.status <> 'finished' then raise exception 'الماتش لسه مخلصش'; end if;
  perform public.fn_admin_log('match_' || p_action, p_match::text,
    jsonb_build_object('teams', m.teams[1] || ' ضد ' || m.teams[2]));
  if p_action = 'approve' then
    update public.matches set review_status = 'approved', review_due = null where id = p_match;
  elsif p_action = 'void' then
    delete from public.events where match_id = p_match;
    update public.matches set review_status = 'void', review_due = null where id = p_match;
    if m.organizer_id is not null then
      insert into public.notifications (title, body, kind, user_id, match_id)
      values ('🚫 ماتشك اتلغى', m.teams[1] || ' ضد ' || m.teams[2] || ' — الإدارة لغت الأحداث بعد المراجعة',
              'review', m.organizer_id, p_match);
    end if;
  elsif p_action = 'reopen' then
    perform public.fn_reset_reviews(p_match);
    update public.matches set review_status = 'pending', review_due = now() + public.fn_review_window()
    where id = p_match;
    perform public.fn_ask_reviewers(p_match);
  else
    raise exception 'إجراء مش معروف';
  end if;
end $$;
grant execute on function public.resolve_match(uuid, text) to authenticated;

create or replace function public.admin_review_queue()
returns table(id uuid, teams text[], date_time timestamptz, score_a int, score_b int, review_status text,
              review_due timestamptz, flags text[], organizer_name text, reviews jsonb)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() and public.am_supervisor() is null then raise exception 'للأدمن أو مشرف المنطقة بس'; end if;
  return query
  select m.id, m.teams, m.date_time, m.score_a, m.score_b, m.review_status, m.review_due, m.flags, o.name,
    coalesce((select jsonb_agg(jsonb_build_object('name', p.name, 'team', r.team, 'ok', r.ok, 'note', r.note)
                               order by r.created_at)
              from public.match_reviews r join public.profiles p on p.id = r.user_id
              where r.match_id = m.id), '[]'::jsonb)
  from public.matches m
  left join public.profiles o on o.id = m.organizer_id
  where (m.review_status = 'disputed' or (m.review_status = 'pending' and cardinality(m.flags) > 0))
    and public.fn_can_judge(m.id)
  order by (m.review_status = 'disputed') desc, m.date_time desc
  limit 100;
end $$;
grant execute on function public.admin_review_queue() to authenticated;

-- الاعتماد بالسكوت: كمان لازم ميكونش فيه علامة كابتن مشبوه
create or replace function public.fn_review_tick()
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in update public.matches m set review_status = 'approved', review_due = null
           where m.review_status = 'pending' and m.review_due <= now()
             and (m.organizer_id is null or public.fn_trusted(m.organizer_id))
             and not (m.flags && array['fresh_captain', 'closed_pair'])
             and cardinality(coalesce(public.fn_captain_flags(m.id), '{}')) = 0
           returning m.id, m.teams, m.flags loop
    if cardinality(r.flags) > 0 and r.flags <> array['new_organizer'] then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🔎 ماتش اتعتمد لوحده وعليه علامات', r.teams[1] || ' ضد ' || r.teams[2] || ' — راجعه، ولو فيه غش الغيه',
             'review', p.id, r.id
      from public.profiles p where p.role = 'manager';
    end if;
  end loop;
  for r in select m.id, m.teams, m.opp_captain, m.zone_id, m.organizer_id from public.matches m
           where m.review_status = 'pending' and m.review_due <= now() loop
    insert into public.app_jobs (key) values ('review-nudge:' || r.id) on conflict do nothing;
    if found then
      -- عشان يظهر في طابور المراجعة
      update public.matches set flags = array(select distinct unnest(flags || array['new_organizer']))
      where id = r.id and cardinality(flags) = 0;
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🔎 ماتش مستني اعتمادك', r.teams[1] || ' ضد ' || r.teams[2]
               || case when r.opp_captain is null then ' — المدير صاحب الفريقين' else ' — محتاج تأكيد' end,
             'review', p.id, r.id
      from public.profiles p
      where p.role = 'manager' or (p.supervisor_zone = r.zone_id and p.id is distinct from r.organizer_id
                                   and p.id is distinct from r.opp_captain);
    end if;
  end loop;
end $$;

-- ═══ 51-ي. الملاعب: البطولات من صاحب الملعب · مكان كل ماتش · أخبار الملعب · إحصائيات وأسطورة الملعب ═══
-- ١) الأدمن بيوثّق الملعب. البطولة بتتعمل من صاحب ملعب موثّق بس (أو الأدمن) وبتتلعب في الملعب ده،
--    وصاحب الملعب بيدير ماتشات بطولته (تشكيلة · أهداف · لاعيبة الفرق) حتى لو مش مدير منطقة.
-- ٢) كل ماتش جديد من مدير لازم يبقى عليه الملعب: من ملاعب الأبلكيشن، أو اسم + عنوان بإيده.
-- ٣) صاحب الملعب الموثّق يعلن عن تعديل أو تجديد → إشعار لأهل المنطقة (إعلان واحد كل ٢٤ ساعة).
--    التجديد (مرة كل ٣٠ يوم) بيبدأ التقييم من الأول: القديم بيفضل ظاهر بس مبيدخلش في المتوسط.
-- ٤) إحصائيات الملعب + أسطورة الملعب (أكتر لاعب أهداف + أسيستات في ماتشات الملعب اللي خلصت).
alter table public.venues add column if not exists zone_id int references public.zones(id);
alter table public.venues add column if not exists verified boolean not null default false;
alter table public.venues add column if not exists renovated_at timestamptz;
alter table public.venues add column if not exists verify_requested_at timestamptz;   -- صاحبه طلب التوثيق
update public.venues v set zone_id = p.zone_id from public.profiles p where v.zone_id is null and p.id = v.owner_id;

-- المنطقة والتوثيق وتاريخ التجديد: السيرفر والأدمن بس (المنطقة من صاحب الملعب)
create or replace function public.trg_venue_guard()
returns trigger language plpgsql as $$
declare client boolean := current_user in ('authenticated', 'anon') and not public.is_manager();
begin
  if tg_op = 'INSERT' then
    if client then
      new.verified := false;
      new.renovated_at := null;
      new.verify_requested_at := null;
      new.zone_id := null;
    end if;
    new.zone_id := coalesce(new.zone_id,
                            (select zone_id from public.profiles where id = coalesce(new.owner_id, auth.uid())));
  elsif client then
    new.verified := old.verified;
    new.renovated_at := old.renovated_at;
    new.verify_requested_at := old.verify_requested_at;
    new.zone_id := old.zone_id;
  end if;
  return new;
end $$;
drop trigger if exists venues_guard on public.venues;
create trigger venues_guard before insert or update on public.venues
for each row execute function public.trg_venue_guard();

-- ⏸ توثيق الملاعب متجمّد لحد ما الأبلكيشن ينزل ويبقى فيه يوزرز كتير (قرار ٢٠٢٦-١١-١٦):
--   false = أي صاحب ملعب يعمل بطولات ويعلن لأهل منطقته من غير توثيق · true = لازم الأدمن/المشرف يوثّق.
--   لازم يفضل زي kVenueVerify في lib/core/app_mode.dart.
create or replace function public.fn_venue_verify_required()
returns boolean language sql immutable as $$ select false; $$;

-- صاحب ملعب (موثّق، أو أي صاحب ملعب والتوثيق متجمّد) — بيستخدمها الأبلكيشن والسياسات
create or replace function public.is_venue_host()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.venues
                 where owner_id = auth.uid() and (verified or not public.fn_venue_verify_required()))
     and public.fn_me_active();
$$;
grant execute on function public.is_venue_host() to authenticated;

-- (أدمن) توثيق ملعب أو شيل التوثيق
create or replace function public.verify_venue(p_venue uuid, p_on boolean)
returns void language plpgsql security definer set search_path = public as $$
declare v public.venues;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  update public.venues set verified = p_on where id = p_venue returning * into v;
  if v.id is null then raise exception 'الملعب مش موجود'; end if;
  perform public.fn_admin_log(case when p_on then 'verify_venue' else 'unverify_venue' end, p_venue::text,
                              jsonb_build_object('name', v.name));
  if p_on and v.owner_id is not null then
    insert into public.notifications (title, body, kind, user_id, link)
    values ('✅ ملعبك اتوثّق', v.name || ' — تقدر دلوقتي تعمل بطولات وتعلن لأهل منطقتك عن أي جديد',
            'event', v.owner_id, 'venue:' || p_venue);
  end if;
end $$;
grant execute on function public.verify_venue(uuid, boolean) to authenticated;

-- ── البطولات من صاحب الملعب ──
alter table public.tournaments add column if not exists venue_id uuid references public.venues(id) on delete set null;

drop function if exists public.create_tournament(text, text, int, int, timestamptz, text, text, int);
create or replace function public.create_tournament(p_name text, p_format text, p_team_count int, p_groups int,
                                                    p_starts timestamptz, p_prize text default null,
                                                    p_sponsor text default null, p_zone int default null,
                                                    p_venue uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v public.venues; z int; tid uuid;
begin
  perform public.fn_assert_active();
  select * into v from public.venues where id = p_venue;
  if v.id is null then raise exception 'اختار الملعب اللي البطولة هتتلعب فيه'; end if;
  if not public.is_manager() then
    if v.owner_id is distinct from auth.uid() then raise exception 'البطولات بتتعمل من صاحب الملعب بس'; end if;
    if not v.verified and public.fn_venue_verify_required() then
      raise exception 'ملعبك لسه مش موثّق — كلّم الإدارة توثّقه الأول';
    end if;
    if (select count(*) from public.tournaments where created_by = auth.uid() and status <> 'finished') >= 3 then
      raise exception 'عندك ٣ بطولات شغالة — خلّص واحدة الأول';
    end if;
  end if;
  z := coalesce(v.zone_id, case when public.is_manager() then p_zone end);
  if z is null then raise exception 'الملعب ده مالوش منطقة — كلّم الإدارة'; end if;
  if p_format = 'groups' and (p_groups < 2 or p_groups * 2 > p_team_count) then
    raise exception 'المجموعات: من ٢ لحد نص عدد الفرق';
  end if;
  insert into public.tournaments (name, zone_id, format, team_count, groups_count, starts_at, prize, sponsor,
                                  created_by, venue_id)
  values (trim(p_name), z, p_format, p_team_count, case when p_format = 'groups' then p_groups else 0 end, p_starts,
          nullif(trim(p_prize), ''), nullif(trim(p_sponsor), ''), auth.uid(), v.id)
  returning id into tid;
  insert into public.notifications (title, body, kind, audience, zone_id, link)
  values ('🏆 بطولة جديدة: ' || trim(p_name),
          'في ' || v.name || ' — التسجيل مفتوح، سجّل فريقك'
            || coalesce(' · الجايزة: ' || nullif(trim(p_prize), ''), ''),
          'match', 'zone', z, 'tournament:' || tid);
  return tid;
end $$;
grant execute on function public.create_tournament(text, text, int, int, timestamptz, text, text, int, uuid)
  to authenticated;

-- ماتش بطولة: باسم صاحب البطولة (إلا لو أدمن) وفي ملعبها — الميعاد مؤقت لحد ما المنظّم يحدده (قسم ٤٥)
create or replace function public.fn_tournament_match(p_t uuid, a text, b text, p_stage text, p_day int)
returns uuid language plpgsql security definer set search_path = public as $$
declare t public.tournaments; mid uuid; n int;
begin
  select * into t from public.tournaments where id = p_t;
  select count(*) into n from public.matches where tournament_id = p_t;
  insert into public.matches (teams, date_time, week, organizer_id, tournament_id, stage, zone_id, time_set, venue_id)
  values (array[a, b],
          timestamptz '2099-01-04 12:00:00+00' + p_day * interval '10 minutes' + n * interval '1 second',
          0,
          case when not exists (select 1 from public.profiles where id = t.created_by and role = 'manager')
               then t.created_by end, p_t, p_stage, t.zone_id, false, t.venue_id)
  returning id into mid;
  return mid;
end $$;

-- منظّم الماتش: مدير المنطقة لماتشاته، أو صاحب البطولة لماتشات بطولته
create or replace function public.fn_organizes(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.matches m join public.profiles p on p.id = auth.uid()
                where m.id = p_match and m.organizer_id = auth.uid()
                  and (p.role = 'organizer'
                       or (m.tournament_id is not null and public.fn_me_active()
                           and exists (select 1 from public.tournaments t
                                       where t.id = m.tournament_id and t.created_by = auth.uid())))
                  and m.status <> 'finished'
                  and m.review_status in ('open', 'pending'));
$$;

-- صاحب الملعب الموثّق بيضيف لاعيبة لفرق بطولته (الفرق اللي هو صاحبها — الـ trigger بيتأكد)
drop policy if exists "players organizer insert" on public.players;
create policy "players organizer insert" on public.players for insert to authenticated
  with check ((public.is_organizer() or public.is_venue_host())
              and (select count(*) from public.players p where p.created_by = auth.uid()) < 300);
drop policy if exists "players organizer update" on public.players;
create policy "players organizer update" on public.players for update to authenticated
  using (created_by = auth.uid() and (public.is_organizer() or public.is_venue_host()))
  with check (created_by = auth.uid());

-- زوّد وقت: منظّم الماتش (مدير أو صاحب البطولة) أو الأدمن
create or replace function public.extend_match(p_match uuid, p_minutes int)
returns int language plpgsql security definer set search_path = public as $$
declare m public.matches; v int;
begin
  select * into m from public.matches where id = p_match;
  if m.id is null then raise exception 'الماتش مش موجود'; end if;
  if not (public.is_manager() or public.fn_organizes(p_match)) then raise exception 'مش ماتشك'; end if;
  if m.status <> 'upcoming' then raise exception 'الماتش خلص'; end if;
  if p_minutes not in (15, 30, 60) then raise exception 'زوّد ربع ساعة أو نص ساعة أو ساعة'; end if;
  if m.duration_min + p_minutes > 300 then raise exception 'أقصى مدة للماتش ٥ ساعات'; end if;
  update public.matches set duration_min = duration_min + p_minutes, end_warned = false
  where id = p_match returning duration_min into v;
  return v;
end $$;
revoke all on function public.extend_match(uuid, int) from public, anon;
grant execute on function public.extend_match(uuid, int) to authenticated;

-- ── مكان الماتش ──
alter table public.matches add column if not exists venue_id uuid references public.venues(id) on delete set null;
alter table public.matches add column if not exists venue_name text;
alter table public.matches add column if not exists venue_address text;
do $$ begin
  alter table public.matches add constraint matches_venue_len
    check (char_length(venue_name) <= 60 and char_length(venue_address) <= 120) not valid;
exception when duplicate_object then null; end $$;
create index if not exists matches_venue on public.matches(venue_id, date_time desc);

create or replace function public.trg_match_venue()
returns trigger language plpgsql as $$
declare v public.venues;
begin
  if new.venue_id is not null and (tg_op = 'INSERT' or new.venue_id is distinct from old.venue_id) then
    select * into v from public.venues where id = new.venue_id;
    new.venue_name := v.name;
    new.venue_address := coalesce(nullif(trim(v.address), ''), new.venue_address);
  end if;
  new.venue_name := nullif(trim(new.venue_name), '');
  new.venue_address := nullif(trim(new.venue_address), '');
  if tg_op = 'INSERT' and new.tournament_id is null
     and current_user in ('authenticated', 'anon') and not public.is_manager()
     and (new.venue_name is null or (new.venue_id is null and new.venue_address is null)) then
    raise exception 'حدد الملعب: اختاره من الملاعب أو اكتب اسمه وعنوانه';
  end if;
  return new;
end $$;
drop trigger if exists matches_venue on public.matches;
create trigger matches_venue before insert or update on public.matches
for each row execute function public.trg_match_venue();

-- ── أخبار الملعب (تعديل · تجديد) ──
create table if not exists public.venue_updates (
  id         uuid primary key default gen_random_uuid(),
  venue_id   uuid not null references public.venues(id) on delete cascade,
  kind       text not null check (kind in ('update', 'renovation')),
  body       text not null check (char_length(body) between 3 and 200),
  created_at timestamptz not null default now()
);
create index if not exists venue_updates_venue on public.venue_updates(venue_id, created_at desc);
alter table public.venue_updates enable row level security;
drop policy if exists "venue updates read" on public.venue_updates;
create policy "venue updates read" on public.venue_updates for select to authenticated using (true);

create or replace function public.post_venue_update(p_venue uuid, p_kind text, p_body text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v public.venues; uid uuid; b text := trim(coalesce(p_body, ''));
begin
  perform public.fn_assert_active();
  select * into v from public.venues where id = p_venue;
  if v.id is null or (v.owner_id is distinct from auth.uid() and not public.is_manager()) then
    raise exception 'مش ملعبك';
  end if;
  if not v.verified and public.fn_venue_verify_required() then
    raise exception 'الإعلان لأهل المنطقة للملاعب الموثّقة بس — كلّم الإدارة';
  end if;
  if v.zone_id is null then raise exception 'الملعب ده مالوش منطقة — كلّم الإدارة'; end if;
  if p_kind not in ('update', 'renovation') then raise exception 'نوع الإعلان غلط'; end if;
  if char_length(b) not between 3 and 200 then raise exception 'اكتب الجديد في الملعب (من ٣ لـ ٢٠٠ حرف)'; end if;
  if exists (select 1 from public.venue_updates where venue_id = p_venue and created_at > now() - interval '24 hours') then
    raise exception 'إعلان واحد كل ٢٤ ساعة للملعب';
  end if;
  if p_kind = 'renovation' and v.renovated_at > now() - interval '30 days' then
    raise exception 'التجديد بيتعلن مرة كل ٣٠ يوم';
  end if;
  insert into public.venue_updates (venue_id, kind, body) values (p_venue, p_kind, b) returning id into uid;
  if p_kind = 'renovation' then update public.venues set renovated_at = now() where id = p_venue; end if;
  insert into public.notifications (title, body, kind, audience, zone_id, link)
  values (case p_kind when 'renovation' then '🏟️ ' || v.name || ' اتجدد' else '📣 جديد في ' || v.name end,
          b || case p_kind when 'renovation' then ' — جرّبه وقيّمه من جديد ⭐' else '' end,
          'event', 'zone', v.zone_id, 'venue:' || p_venue);
  return uid;
end $$;
grant execute on function public.post_venue_update(uuid, text, text) to authenticated;

-- التقييم بعد التجديد: المتوسط من التقييمات الجديدة بس
create or replace function public.venue_ratings()
returns table(venue_id uuid, avg numeric, count bigint)
language sql stable as $$
  select r.venue_id, round(avg(r.stars)::numeric, 1), count(*)
  from public.venue_reviews r join public.venues v on v.id = r.venue_id
  where v.renovated_at is null or r.created_at >= v.renovated_at
  group by r.venue_id;
$$;
grant execute on function public.venue_ratings() to authenticated;

-- وقت التقييم من السيرفر: تعديل النجوم أو الكلام = تقييم جديد (بيدخل في متوسط ما بعد التجديد)
create or replace function public.trg_review_time()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' or (new.stars, new.comment) is distinct from (old.stars, old.comment) then
    new.created_at := now();
  else
    new.created_at := old.created_at;
  end if;
  return new;
end $$;
drop trigger if exists review_time on public.venue_reviews;
create trigger review_time before insert or update on public.venue_reviews
for each row execute function public.trg_review_time();

create or replace function public.trg_review_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare v public.venues;
begin
  if tg_op = 'UPDATE' and new.stars is not distinct from old.stars then return new; end if;
  select * into v from public.venues where id = new.venue_id;
  if v.owner_id is not null then
    insert into public.notifications (title, body, kind, user_id, link)
    values ('⭐ تقييم جديد لملعبك', v.name || ' · ' || repeat('★', new.stars) || coalesce(' — ' || left(new.comment, 80), ''),
            'booking', v.owner_id, 'venue:' || v.id);
  end if;
  return new;
end $$;
drop trigger if exists review_notify on public.venue_reviews;
create trigger review_notify after insert or update on public.venue_reviews
for each row execute function public.trg_review_notify();

-- ── إحصائيات الملعب + أسطورة الملعب ──
-- matches/teams/goals من الماتشات اللي خلصت (مش الملغية) · hours = الماتشات بالساعة آخر ٩٠ يوم
-- top = أكتر ٥ لاعيبة أهداف + أسيستات (الأول = أسطورة الملعب)
create or replace function public.venue_stats(p_venue uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  with ms as (select m.id, m.teams, m.status, m.date_time from public.matches m
              where m.venue_id = p_venue and m.review_status <> 'void'),
  done as (select * from ms where status = 'finished'),
  ev as (select e.player_id, count(*) filter (where e.type = 'goal') as g,
                count(*) filter (where e.type = 'assist') as a, count(distinct e.match_id) as mp
         from public.events e join done d on d.id = e.match_id
         where e.type in ('goal', 'assist') group by e.player_id),
  top as (select pl.id, pl.name, pl.nickname, pl.team, pl.image_url, ev.g, ev.a, ev.mp
          from ev join public.players pl on pl.id = ev.player_id
          order by ev.g + ev.a desc, ev.g desc, pl.name limit 5)
  select jsonb_build_object(
    'matches', (select count(*) from done),
    'upcoming', (select count(*) from ms where status = 'upcoming'),
    'teams', (select count(distinct lower(trim(t))) from done, unnest(done.teams) t),
    'goals', (select coalesce(sum(g), 0) from ev),
    'tournaments', (select count(*) from public.tournaments where venue_id = p_venue),
    'hours', coalesce((select jsonb_object_agg(h, n) from (
               select extract(hour from date_time at time zone 'Africa/Cairo')::int as h, count(*) as n
               from ms where date_time > now() - interval '90 days' group by 1) x), '{}'::jsonb),
    'top', coalesce((select jsonb_agg(to_jsonb(top) order by top.g + top.a desc, top.g desc, top.name) from top),
                    '[]'::jsonb));
$$;
grant execute on function public.venue_stats(uuid) to authenticated;

