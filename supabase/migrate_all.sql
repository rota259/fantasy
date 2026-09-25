-- ═══════════════════════════════════════════════════════════════
-- الخماسي — كل الـ migrations في ملف واحد (شغّله مرة واحدة، وتقدر تعيده)
-- Supabase Dashboard → SQL Editor → New query → الصق الكل → Run
--
-- الأقسام بالترتيب (الترتيب مهم):
--    1) schema             — الجداول الأساسية + الأعمدة الجديدة
--    2) scoring basics     — المدير + نقاط الأحداث + حدود الجولة بالوقت
--    3) lineups            — تشكيلة كل ماتش (المدير)
--    4) picks              — تشكيلة اليوزر لكل ماتش (القراءة بس — الحفظ بدالة save_picks)
--    5) week stats         — نقاط الجولة + الامتلاك + تاريخ اللاعب
--    6) notifications      — صندوق الإشعارات (للكل / ليوزر / لمتابعين ماتش)
--    7) polls              — التصويتات (هدف/تصدّي الجولة والموسم + تعادل تشكيلة الجولة)
--    8) security & admin   — حماية البروفايل + أدوار المستخدمين + الخصوصية
--    9) venues & bookings  — الملاعب (أي يوزر يضيف) + التقييمات + الحجز
--   10) seasons & chips    — الموسم ونصّه + الكروت
--   11) challenge          — تحدّي الجولة: توقّع النتيجة (+٥)
--   12) follows            — متابعة ماتش لايف (٣ في اليوم) + إشعار كل حدث
--   13) ratings            — تقييم الجمهور + رجل المباراة (+٣)
--   14) player claims      — اللاعب الحقيقي يوثّق بروفايله
--   15) scoring v2         — حساب النقاط (الكروت + البونص) + حفظ التشكيلة الآمن
--   16) leagues            — أي يوزر يعمل دوري + المدير يدير
--   17) awards & totw      — تصويتات الموسم + تعادل تشكيلة الجولة + قفل التصويتات
--   18) badges             — الشارات والإنجازات
--   19) tick               — مهمة كل ١٠ دقايق (pg_cron)
--   20) push               — أي إشعار بيتسجّل → push أوتوماتيك (pg_net → Edge Function push)
--
-- ⚠️ كل UPDATE/DELETE لازم يبقى ليه WHERE (Supabase مشغّل pg-safeupdate).
-- الأوقات: الجولة بتوقيت القاهرة (Africa/Cairo).
-- ═══════════════════════════════════════════════════════════════


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 1) SCHEMA                                                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null default '',
  email       text not null default '',
  phone       text,
  role        text not null default 'user',        -- 'user' | 'manager'
  team        text[] not null default '{}',
  league_id   uuid,
  photo_url   text,                                 -- صورة البروفايل
  position    text,
  captain_id  uuid,
  total_points int not null default 0,              -- بيتحسب في السيرفر بس
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);
alter table public.profiles add column if not exists fcm_token    text;
alter table public.profiles add column if not exists referred_by  uuid references public.profiles(id) on delete set null;
alter table public.profiles add column if not exists badges_dirty boolean not null default false;
-- كسر التعادل في الترتيب (بيتحسب في السيرفر لما كل ماتش يبدأ): لاعيبة امتلاكها < ٢٥٪ + متوسط امتلاك اختياراته
alter table public.profiles add column if not exists low_picks int not null default 0;
alter table public.profiles add column if not exists avg_own numeric not null default 100;
create index if not exists profiles_rank on public.profiles (total_points desc, low_picks desc, avg_own);
-- كود الدعوة بتاع اليوزر (٦ حروف) — اللي يسجّل بيه يتحسب في شارة "المؤثر"
alter table public.profiles add column if not exists ref_code text
  default upper(substr(md5(gen_random_uuid()::text), 1, 6));
update public.profiles set ref_code = upper(substr(md5(gen_random_uuid()::text), 1, 6)) where ref_code is null;
create unique index if not exists profiles_ref_code on public.profiles(ref_code);

create table if not exists public.players (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  team          text not null default '',
  position      text not null default '',           -- GK | DEF | MID | FWD
  price         numeric not null default 0,
  image_url     text,
  total_points  int not null default 0,
  form          numeric not null default 0,
  goals         int not null default 0,
  assists       int not null default 0,
  clean_sheets  int not null default 0,
  yellow_cards  int not null default 0,
  availability  text not null default 'ready',       -- ready | injured | doubtful | suspended
  news          text
);
alter table public.players add column if not exists availability text not null default 'ready';
alter table public.players add column if not exists news text;
-- اللاعب الحقيقي اللي وثّق البروفايل ده (يوزر واحد لكل لاعب)
alter table public.players add column if not exists user_id uuid references public.profiles(id) on delete set null;
create unique index if not exists players_user_unique on public.players(user_id) where user_id is not null;

create table if not exists public.matches (
  id         uuid primary key default gen_random_uuid(),
  date_time  timestamptz not null,
  teams      text[] not null default '{}',
  status     text not null default 'upcoming',      -- upcoming | finished
  week       int not null default 0,
  fdr        int not null default 3
);
alter table public.matches add column if not exists score_a int;
alter table public.matches add column if not exists score_b int;
alter table public.matches add column if not exists finished_at timestamptz;          -- وقت ما المدير قفله
alter table public.matches add column if not exists is_challenge boolean not null default false; -- تحدّي الجولة
alter table public.matches add column if not exists motm_player_id uuid references public.players(id) on delete set null;
alter table public.matches add column if not exists motm_done boolean not null default false;
alter table public.matches add column if not exists captains_notified boolean not null default false;
alter table public.matches add column if not exists tiebreak_done boolean not null default false;
create index if not exists matches_status_date on public.matches(status, date_time);
create index if not exists matches_date on public.matches(date_time);

create table if not exists public.leagues (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  type         text not null default 'public',      -- public | private | h2h
  invite_code  text unique
);
alter table public.leagues add column if not exists owner_id uuid references public.profiles(id) on delete set null;
alter table public.leagues add column if not exists created_at timestamptz not null default now();

create table if not exists public.league_members (
  league_id  uuid references public.leagues(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  joined_at  timestamptz not null default now(),
  primary key (league_id, user_id)
);

create table if not exists public.venues (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  price        int not null default 0,
  distance_km  numeric not null default 0,
  surface      text not null default 'نجيلة صناعية',
  feature      text,
  capacity     int not null default 10,
  filled       int not null default 0,
  slot_time    text default ''
);

-- (المزاد اتشال من التطبيق — الجداول القديمة سايبينها زي ما هي من غير استخدام)
create table if not exists public.auctions (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,
  current_player_id uuid references public.players(id) on delete set null,
  base_price        numeric not null default 6,
  ends_at           timestamptz,
  status            text not null default 'live'
);
create table if not exists public.auction_bids (
  id          uuid primary key default gen_random_uuid(),
  auction_id  uuid references public.auctions(id) on delete cascade,
  user_id     uuid references public.profiles(id) on delete cascade,
  bidder_name text not null default '',
  amount      numeric not null,
  created_at  timestamptz not null default now()
);
alter table public.auctions drop constraint if exists auctions_current_player_id_fkey;
alter table public.auctions add constraint auctions_current_player_id_fkey
  foreign key (current_player_id) references public.players(id) on delete set null;

create table if not exists public.events (
  id         uuid primary key default gen_random_uuid(),
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  type       text not null,
  minute     int
);
create index if not exists events_match on public.events(match_id);
create index if not exists events_player on public.events(player_id);

-- الدخول برقم الموبايل: يحوّل الرقم لإيميل
create or replace function public.email_for_phone(p text)
returns text language sql security definer set search_path = public as $$
  select email from public.profiles where phone = p limit 1;
$$;
grant execute on function public.email_for_phone(text) to anon, authenticated;

alter table public.profiles       enable row level security;
alter table public.players        enable row level security;
alter table public.matches        enable row level security;
alter table public.leagues        enable row level security;
alter table public.league_members enable row level security;
alter table public.venues         enable row level security;
alter table public.auctions       enable row level security;
alter table public.auction_bids   enable row level security;
alter table public.events         enable row level security;

drop policy if exists "profiles read"   on public.profiles;
drop policy if exists "profiles insert" on public.profiles;
drop policy if exists "profiles update" on public.profiles;
create policy "profiles read"   on public.profiles for select to authenticated using (true);
create policy "profiles insert" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles update" on public.profiles for update to authenticated using (auth.uid() = id);

drop policy if exists "players read" on public.players;
drop policy if exists "matches read" on public.matches;
drop policy if exists "events read"  on public.events;
drop policy if exists "venues read"  on public.venues;
create policy "players read" on public.players for select to authenticated using (true);
create policy "matches read" on public.matches for select to authenticated using (true);
create policy "events read"  on public.events  for select to authenticated using (true);
create policy "venues read"  on public.venues  for select to authenticated using (true);

drop policy if exists "auctions read" on public.auctions;
drop policy if exists "bids read"     on public.auction_bids;
drop policy if exists "bids insert"   on public.auction_bids;

drop policy if exists "members read"   on public.league_members;
drop policy if exists "members insert" on public.league_members;
drop policy if exists "members delete" on public.league_members;
create policy "members read"   on public.league_members for select to authenticated using (true);
create policy "members insert" on public.league_members for insert to authenticated with check (auth.uid() = user_id);


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 2) SCORING BASICS                                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

create or replace function public.is_manager()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'manager');
$$;

drop policy if exists "players manager write" on public.players;
create policy "players manager write" on public.players for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

drop policy if exists "matches manager write" on public.matches;
create policy "matches manager write" on public.matches for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

drop policy if exists "events manager write" on public.events;
create policy "events manager write" on public.events for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

-- نقاط الحدث حسب النوع والمركز (نفس PointsEngine في Dart بالظبط)
create or replace function public.fn_event_points(p_type text, p_pos text)
returns int language sql immutable as $$
  select case
    when p_type = 'appearance'  then 1
    when p_type = 'goal'        then case when p_pos in ('GK','DEF') then 6 when p_pos='MID' then 5 else 4 end
    when p_type = 'assist'      then 3
    when p_type = 'cleanSheet'  then case when p_pos in ('GK','DEF') then 4 when p_pos='MID' then 1 else 0 end
    when p_type = 'save'        then 1
    when p_type = 'penaltySave' then 5
    when p_type = 'motm'        then 3     -- رجل المباراة (تصويت الجمهور)
    when p_type = 'bonus'       then 3
    when p_type = 'yellowCard'  then -1
    when p_type = 'redCard'     then -3
    when p_type = 'ownGoal'     then -2
    when p_type = 'penaltyMiss' then -2
    else 0
  end;
$$;

-- اسم الحدث بالعربي (للإشعارات)
create or replace function public.fn_event_label(p_type text)
returns text language sql immutable as $$
  select case p_type
    when 'goal' then 'جوووول ⚽' when 'assist' then 'أسيست 🎯' when 'cleanSheet' then 'شباك نظيفة 🧤'
    when 'save' then 'تصدّي 🧤' when 'penaltySave' then 'صدّ بلنتي 🧤' when 'motm' then 'رجل المباراة ⭐'
    when 'bonus' then 'بونص ➕' when 'yellowCard' then 'كارت أصفر 🟨' when 'redCard' then 'كارت أحمر 🟥'
    when 'ownGoal' then 'جول عكسي' when 'penaltyMiss' then 'أضاع بلنتي' else p_type end;
$$;

-- إحصائيات اللاعب من أحداثه (الفورمة = متوسط آخر ٣ جولات)
create or replace function public.fn_recalc_player(p_player uuid)
returns void language sql security definer set search_path = public as $$
  update public.players pl set
    total_points = coalesce((
      select sum(public.fn_event_points(e.type, pl.position))
      from public.events e where e.player_id = pl.id), 0),
    goals        = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'goal'),
    assists      = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'assist'),
    clean_sheets = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'cleanSheet'),
    yellow_cards = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'yellowCard'),
    form = coalesce((
      select round(avg(w.pts)::numeric, 1) from (
        select m.week, sum(public.fn_event_points(e.type, pl.position)) as pts
        from public.events e join public.matches m on m.id = e.match_id
        where e.player_id = pl.id
        group by m.week order by m.week desc limit 3
      ) w), 0)
  where pl.id = p_player;
$$;

-- نهاية الجولة اللي فيها وقت معيّن = أول جمعة الساعة ٤ الفجر (القاهرة) بعده أو عنده.
-- (نفس WeekWindow في Dart: الماتش في الجولة لو start < date_time <= cutoff)
create or replace function public.fn_week_cutoff(ts timestamptz)
returns timestamptz language sql stable as $$
  select (case when c < l then c + interval '7 days' else c end) at time zone 'Africa/Cairo'
  from (select ts at time zone 'Africa/Cairo' as l) x,
  lateral (select l::date + ((5 - extract(isodow from l)::int + 7) % 7) * interval '1 day'
                  + interval '4 hours' as c) y;
$$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 3) LINEUPS                                                     ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.lineups (
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  status     text not null default 'bench',   -- starting | bench
  primary key (match_id, player_id)
);
alter table public.lineups enable row level security;

drop policy if exists "lineups read" on public.lineups;
create policy "lineups read" on public.lineups for select to authenticated using (true);
drop policy if exists "lineups manager write" on public.lineups;
create policy "lineups manager write" on public.lineups for all to authenticated
  using (public.is_manager()) with check (public.is_manager());


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 4) PICKS                                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.picks (
  user_id    uuid references public.profiles(id) on delete cascade,
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  status     text not null default 'starting',   -- starting | bench
  is_captain boolean not null default false,
  is_vice    boolean not null default false,
  primary key (user_id, match_id, player_id)
);
alter table public.picks add column if not exists is_vice boolean not null default false;
alter table public.picks add column if not exists saved_at timestamptz not null default now();
create index if not exists picks_match on public.picks(match_id);
create index if not exists picks_player on public.picks(player_id);
alter table public.picks enable row level security;

-- تشكيلتك تشوفها دايمًا. تشكيلات الناس تبان بعد ما الماتش يقفل بس (محدش ينقل من حد).
drop policy if exists "picks read" on public.picks;
create policy "picks read" on public.picks for select to authenticated using (
  user_id = auth.uid() or public.is_manager()
  or exists(select 1 from public.matches m where m.id = match_id and m.date_time - interval '1 hour' <= now())
);
-- مفيش كتابة مباشرة: الحفظ بدالة save_picks (قسم 15) عشان التحقّق يبقى في السيرفر.
drop policy if exists "picks own write" on public.picks;
drop trigger if exists picks_recalc on public.picks;
drop trigger if exists profile_recalc on public.profiles;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 5) WEEK STATS                                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

create or replace function public.player_week_points(w int)
returns table(id uuid, name text, team text, "position" text, points bigint)
language sql stable as $$
  select pl.id, pl.name, pl.team, pl.position,
    coalesce(sum(public.fn_event_points(e.type, pl.position)), 0)::bigint as points
  from public.players pl
  join public.events e on e.player_id = pl.id
  join public.matches m on m.id = e.match_id and m.week = w
  group by pl.id, pl.name, pl.team, pl.position
  having coalesce(sum(public.fn_event_points(e.type, pl.position)), 0) <> 0
  order by points desc;
$$;
grant execute on function public.player_week_points(int) to authenticated;

create or replace function public.player_gw_stats(w int)
returns table(id uuid, points bigint, owners bigint, ownership numeric,
              transfers_in bigint, transfers_out bigint)
language sql stable security definer set search_path = public as $$
  with cur as (
    select distinct pk.user_id, pk.player_id from public.picks pk
    join public.matches m on m.id = pk.match_id where m.week = w
  ), prev as (
    select distinct pk.user_id, pk.player_id from public.picks pk
    join public.matches m on m.id = pk.match_id where m.week = w - 1
  ), total as (
    select greatest(count(distinct user_id), 1) as n from cur
  )
  select pl.id,
    coalesce((select sum(public.fn_event_points(e.type, pl.position))
              from public.events e join public.matches m on m.id = e.match_id
              where e.player_id = pl.id and m.week = w), 0)::bigint,
    (select count(*) from cur c where c.player_id = pl.id)::bigint,
    round((select count(*) from cur c where c.player_id = pl.id) * 100.0 / (select n from total), 1),
    (select count(*) from cur c where c.player_id = pl.id and not exists (
       select 1 from prev p where p.user_id = c.user_id and p.player_id = pl.id))::bigint,
    (select count(*) from prev p where p.player_id = pl.id and not exists (
       select 1 from cur c where c.user_id = p.user_id and c.player_id = pl.id))::bigint
  from public.players pl;
$$;
grant execute on function public.player_gw_stats(int) to authenticated;

create or replace function public.player_history(p uuid)
returns table(gw int, points bigint)
language sql stable as $$
  select m.week, coalesce(sum(public.fn_event_points(e.type, pl.position)), 0)::bigint
  from public.events e
  join public.matches m on m.id = e.match_id
  join public.players pl on pl.id = e.player_id
  where e.player_id = p
  group by m.week order by m.week;
$$;
grant execute on function public.player_history(uuid) to authenticated;

-- نقاط كل لاعب في فترة + صورته (صورة اللاعب، ولو مفيش صورة اليوزر اللي وثّقه) + موثّق ولا لأ
drop function if exists public.player_points_between(timestamptz, timestamptz);
create or replace function public.player_points_between(p_from timestamptz, p_to timestamptz)
returns table(id uuid, name text, team text, "position" text, points bigint,
              image_url text, verified boolean)
language sql stable security definer set search_path = public as $$
  select pl.id, pl.name, pl.team, pl.position,
    sum(public.fn_event_points(e.type, pl.position))::bigint as points,
    coalesce(pl.image_url, (select pr.photo_url from public.profiles pr where pr.id = pl.user_id)),
    pl.user_id is not null
  from public.events e
  join public.matches m on m.id = e.match_id and m.date_time > p_from and m.date_time <= p_to
  join public.players pl on pl.id = e.player_id
  group by pl.id, pl.name, pl.team, pl.position, pl.image_url, pl.user_id
  having sum(public.fn_event_points(e.type, pl.position)) <> 0
  order by points desc, pl.name;
$$;
grant execute on function public.player_points_between(timestamptz, timestamptz) to authenticated;

-- الامتلاك الحقيقي في الجولة (security definer: التشكيلات مخفية قبل القفل بس الأرقام الإجمالية مسموحة)
create or replace function public.player_window_stats(p_from timestamptz, p_to timestamptz)
returns table(id uuid, points bigint, owners bigint, ownership numeric,
              transfers_in bigint, transfers_out bigint, managers bigint)
language sql stable security definer set search_path = public as $$
  with cur as (
    select distinct pk.user_id, pk.player_id from public.picks pk
    join public.matches m on m.id = pk.match_id
    where m.date_time > p_from and m.date_time <= p_to
  ), prev as (
    select distinct pk.user_id, pk.player_id from public.picks pk
    join public.matches m on m.id = pk.match_id
    where m.date_time > p_from - interval '7 days' and m.date_time <= p_from
  ), total as (
    select count(distinct user_id) as n from cur
  ), pts as (
    select e.player_id, sum(public.fn_event_points(e.type, pl.position)) as p
    from public.events e
    join public.matches m on m.id = e.match_id and m.date_time > p_from and m.date_time <= p_to
    join public.players pl on pl.id = e.player_id
    group by e.player_id
  ), own as (
    select cur.player_id, count(*) as n from cur group by cur.player_id
  ), tin as (
    select c.player_id, count(*) as n from cur c
    left join prev p on p.user_id = c.user_id and p.player_id = c.player_id
    where p.user_id is null group by c.player_id
  ), tout as (
    select p.player_id, count(*) as n from prev p
    left join cur c on c.user_id = p.user_id and c.player_id = p.player_id
    where c.user_id is null group by p.player_id
  )
  select pl.id, coalesce(pts.p, 0)::bigint, coalesce(own.n, 0)::bigint,
    case when total.n = 0 then 0 else round(coalesce(own.n, 0) * 100.0 / total.n, 1) end,
    coalesce(tin.n, 0)::bigint, coalesce(tout.n, 0)::bigint, total.n::bigint
  from public.players pl
  cross join total
  left join pts on pts.player_id = pl.id
  left join own on own.player_id = pl.id
  left join tin on tin.player_id = pl.id
  left join tout on tout.player_id = pl.id;
$$;
grant execute on function public.player_window_stats(timestamptz, timestamptz) to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 6) NOTIFICATIONS                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  body       text not null default '',
  kind       text not null default 'event',   -- lineup | match | event | status | booking | badge | vote | challenge
  match_id   uuid references public.matches(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.notifications add column if not exists kind text not null default 'event';
alter table public.notifications add column if not exists user_id uuid references public.profiles(id) on delete cascade;
-- الجمهور: all = الكل · user = يوزر واحد (user_id) · match = متابعين الماتش (match_id)
alter table public.notifications add column if not exists audience text not null default 'all';
update public.notifications set audience = 'user' where user_id is not null and audience = 'all';
create index if not exists notifications_created on public.notifications(created_at desc);
create index if not exists notifications_user on public.notifications(user_id);
create index if not exists notifications_match on public.notifications(match_id);

-- أي صف فيه user_id يبقى موجّه لليوزر ده بس
create or replace function public.trg_notifications_audience()
returns trigger language plpgsql as $$
begin
  if new.user_id is not null then
    new.audience := 'user';
  elsif new.audience = 'user' then
    raise exception 'إشعار موجّه من غير user_id';   -- عمره ما يتحوّل للكل بالغلط
  elsif new.audience = 'match' and new.match_id is null then
    raise exception 'إشعار متابعين من غير match_id';
  elsif new.audience not in ('all', 'match') then
    raise exception 'audience غلط: %', new.audience;
  end if;
  return new;
end $$;
drop trigger if exists notifications_audience on public.notifications;
create trigger notifications_audience before insert on public.notifications
for each row execute function public.trg_notifications_audience();

alter table public.notifications enable row level security;
-- (سياسة القراءة بتتعمل في قسم 12 بعد جدول المتابعة)
drop policy if exists "notifications manager write" on public.notifications;
create policy "notifications manager write" on public.notifications
  for insert to authenticated with check (public.is_manager());

do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 7) POLLS                                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.polls (
  id         uuid primary key default gen_random_uuid(),
  kind       text not null,        -- goal_week | save_week | goal_season | save_season | totw_tie
  question   text not null default '',
  active     boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.polls add column if not exists window_end timestamptz;   -- الجولة (للتعادل)
alter table public.polls add column if not exists closes_at  timestamptz;   -- بيتقفل لوحده
alter table public.polls add column if not exists slots      int not null default 1; -- كام فايز

create table if not exists public.poll_options (
  id        uuid primary key default gen_random_uuid(),
  poll_id   uuid references public.polls(id) on delete cascade,
  label     text not null,
  player_id uuid references public.players(id) on delete set null
);
alter table public.poll_options add column if not exists video_url text;   -- لينك فيديو الهدف/التصدّي
alter table public.poll_options add column if not exists match_id uuid references public.matches(id) on delete set null;

create table if not exists public.poll_votes (
  poll_id    uuid references public.polls(id) on delete cascade,
  option_id  uuid references public.poll_options(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (poll_id, user_id)
);
create index if not exists poll_votes_option on public.poll_votes(option_id);
create index if not exists poll_options_poll on public.poll_options(poll_id);
create index if not exists polls_kind on public.polls(kind, created_at desc);

alter table public.polls        enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes   enable row level security;

drop policy if exists "polls read" on public.polls;
create policy "polls read" on public.polls for select to authenticated using (true);
drop policy if exists "polls manager write" on public.polls;
create policy "polls manager write" on public.polls for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

drop policy if exists "poll_options read" on public.poll_options;
create policy "poll_options read" on public.poll_options for select to authenticated using (true);
drop policy if exists "poll_options manager write" on public.poll_options;
create policy "poll_options manager write" on public.poll_options for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

drop policy if exists "poll_votes read" on public.poll_votes;
create policy "poll_votes read" on public.poll_votes for select to authenticated using (true);
drop policy if exists "poll_votes own write" on public.poll_votes;
-- اليوزر يصوّت بنفسه، على تصويت مفتوح ومعدّاش ميعاد قفله، ولاختيار من نفس التصويت.
create policy "poll_votes own write" on public.poll_votes for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id
    and exists (select 1 from public.polls p where p.id = poll_id and p.active
                and (p.closes_at is null or p.closes_at > now()))
    and exists (select 1 from public.poll_options o where o.id = option_id and o.poll_id = poll_votes.poll_id));

do $$ begin
  alter publication supabase_realtime add table public.poll_votes;
exception when duplicate_object then null; end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 8) SECURITY & ADMIN                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- حماية البروفايل: اليوزر ميقدرش يغيّر دوره ولا نقطه ولا مين دعاه من التطبيق.
-- (الدوال بتاعة السيرفر بتشتغل بصلاحية postgres فمش بتتأثّر)
create or replace function public.trg_profiles_guard()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.role := 'user';
      new.total_points := 0;
      new.referred_by := null;
      new.badges_dirty := false;
      new.low_picks := 0;
      new.avg_own := 100;
      new.ref_code := upper(substr(md5(gen_random_uuid()::text), 1, 6));
    else
      new.role := old.role;
      new.total_points := old.total_points;
      new.referred_by := old.referred_by;
      new.badges_dirty := old.badges_dirty;
      new.ref_code := old.ref_code;
      new.email := old.email;
      new.low_picks := old.low_picks;
      new.avg_own := old.avg_own;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists profiles_guard on public.profiles;
create trigger profiles_guard before insert or update on public.profiles
for each row execute function public.trg_profiles_guard();

-- الخصوصية: الإيميل والموبايل وتوكن الإشعارات مخفيين عن باقي اليوزرز.
-- بروفايلك كامل بـ my_profile()، والمدير بـ admin_users().
revoke select on public.profiles from anon, authenticated;
grant select (id, name, role, photo_url, total_points, created_at, is_active, team,
              league_id, position, captain_id) on public.profiles to authenticated;

create or replace function public.my_profile()
returns setof public.profiles language sql stable security definer set search_path = public as $$
  select * from public.profiles where id = auth.uid();
$$;
grant execute on function public.my_profile() to authenticated;

create or replace function public.admin_users()
returns table(id uuid, name text, email text, phone text, role text, total_points int,
              photo_url text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  return query select p.id, p.name, p.email, p.phone, p.role, p.total_points, p.photo_url, p.created_at
    from public.profiles p order by p.total_points desc;
end $$;
grant execute on function public.admin_users() to authenticated;

create or replace function public.set_user_role(uid uuid, new_role text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'not allowed'; end if;
  if new_role not in ('user', 'manager') then raise exception 'bad role'; end if;
  update public.profiles set role = new_role where id = uid;
end; $$;
grant execute on function public.set_user_role(uuid, text) to authenticated;

-- كود الدعوة: اليوزر الجديد يكتب كود صاحبه (مرة واحدة، خلال أول ٧ أيام)
create or replace function public.apply_referral(p_code text)
returns void language plpgsql security definer set search_path = public as $$
declare me public.profiles; ref uuid;
begin
  select * into me from public.profiles where id = auth.uid();
  if not found then raise exception 'سجّل دخولك الأول'; end if;
  if me.referred_by is not null then raise exception 'كتبت كود دعوة قبل كده'; end if;
  if me.created_at < now() - interval '7 days' then raise exception 'كود الدعوة للحسابات الجديدة بس'; end if;
  select id into ref from public.profiles where ref_code = upper(trim(p_code));
  if ref is null then raise exception 'الكود مش صحيح'; end if;
  if ref = me.id then raise exception 'ماينفعش تكتب كودك'; end if;
  update public.profiles set referred_by = ref where id = me.id;
  update public.profiles set badges_dirty = true where id = ref;
end $$;
grant execute on function public.apply_referral(text) to authenticated;

-- صور البروفايل: كل يوزر يرفع في فولدر باسمه بس
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 3145728, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "avatars read" on storage.objects;
create policy "avatars read" on storage.objects for select using (bucket_id = 'avatars');
drop policy if exists "avatars own write" on storage.objects;
create policy "avatars own write" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "avatars own delete" on storage.objects;
create policy "avatars own delete" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- صور اللاعيبة: المدير بس
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('player-photos', 'player-photos', true, 3145728, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "player photos read" on storage.objects;
create policy "player photos read" on storage.objects for select using (bucket_id = 'player-photos');
drop policy if exists "player photos manager write" on storage.objects;
create policy "player photos manager write" on storage.objects for insert to authenticated
  with check (bucket_id = 'player-photos' and public.is_manager());
drop policy if exists "player photos manager delete" on storage.objects;
create policy "player photos manager delete" on storage.objects for delete to authenticated
  using (bucket_id = 'player-photos' and public.is_manager());


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 9) VENUES & BOOKINGS                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

alter table public.venues add column if not exists lat        double precision;
alter table public.venues add column if not exists lng        double precision;
alter table public.venues add column if not exists phone      text;
alter table public.venues add column if not exists address    text;
alter table public.venues add column if not exists open_hour  int not null default 16;
alter table public.venues add column if not exists close_hour int not null default 24;
alter table public.venues add column if not exists photos     text[] not null default '{}';
alter table public.venues add column if not exists owner_id   uuid references public.profiles(id) on delete set null;
alter table public.venues add column if not exists maps_url   text;
alter table public.venues add column if not exists created_at timestamptz not null default now();
do $$ begin
  alter table public.venues add constraint venues_hours_chk
    check (open_hour between 0 and 23 and close_hour > open_hour and close_hour <= 30);
exception when duplicate_object then null; end $$;

-- أي يوزر يضيف ملعب ويبقى صاحبه (بحد ٥ ملاعب). صاحبه يعدّل ويحذف، والمدير يقدر على الكل.
drop policy if exists "venues manager write" on public.venues;
drop policy if exists "venues insert" on public.venues;
drop policy if exists "venues update" on public.venues;
drop policy if exists "venues delete" on public.venues;
create policy "venues insert" on public.venues for insert to authenticated with check (
  public.is_manager()
  or (owner_id = auth.uid()
      and (select count(*) from public.venues v where v.owner_id = auth.uid()) < 5)
);
create policy "venues update" on public.venues for update to authenticated
  using (owner_id = auth.uid() or public.is_manager())
  with check (owner_id = auth.uid() or public.is_manager());
create policy "venues delete" on public.venues for delete to authenticated
  using (owner_id = auth.uid() or public.is_manager());

create table if not exists public.bookings (
  id         uuid primary key default gen_random_uuid(),
  venue_id   uuid not null references public.venues(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  day        date not null,
  hour       int  not null,
  status     text not null default 'pending',   -- pending | confirmed | rejected | cancelled
  note       text,
  created_at timestamptz not null default now()
);
create unique index if not exists bookings_one_active_per_slot
  on public.bookings (venue_id, day, hour) where status in ('pending', 'confirmed');
alter table public.bookings enable row level security;

-- الحجز بيانات شخصية: يشوفه صاحبه وصاحب الملعب والمدير بس.
-- المواعيد المحجوزة لباقي الناس بتيجي من venue_slots() من غير أسماء.
drop policy if exists "bookings read" on public.bookings;
create policy "bookings read" on public.bookings for select to authenticated using (
  user_id = auth.uid() or public.is_manager()
  or exists (select 1 from public.venues v where v.id = venue_id and v.owner_id = auth.uid())
);
drop policy if exists "bookings request" on public.bookings;
create policy "bookings request" on public.bookings for insert to authenticated
  with check (
    auth.uid() = user_id and status = 'pending' and day >= current_date
    and exists (select 1 from public.venues v
                where v.id = venue_id and hour >= v.open_hour and hour < v.close_hour)
  );

-- المواعيد المشغولة في ملعب (من غير بيانات الحاجز) — user_id بيرجع بس لو الحجز بتاعك.
create or replace function public.venue_slots(p_venue uuid, p_from date, p_to date)
returns table(id uuid, venue_id uuid, user_id uuid, day date, hour int, status text)
language sql stable security definer set search_path = public as $$
  select b.id, b.venue_id, case when b.user_id = auth.uid() then b.user_id end, b.day, b.hour, b.status
  from public.bookings b
  where b.venue_id = p_venue and b.day between p_from and p_to and b.status in ('pending', 'confirmed');
$$;
grant execute on function public.venue_slots(uuid, date, date) to authenticated;

-- قايمة حجوزات بالأسماء: mine = حجوزاتي · owner = طلبات ملاعبي · all = الكل (المدير)
create or replace function public.booking_list(p_scope text)
returns setof json language sql stable security definer set search_path = public as $$
  select json_build_object(
    'id', b.id, 'venue_id', b.venue_id, 'user_id', b.user_id, 'day', b.day, 'hour', b.hour,
    'status', b.status, 'note', b.note,
    'venues', json_build_object('name', v.name, 'owner_id', v.owner_id),
    'profiles', json_build_object('name', p.name,
       'phone', case when v.owner_id = auth.uid() or public.is_manager() then p.phone end))
  from public.bookings b
  join public.venues v on v.id = b.venue_id
  join public.profiles p on p.id = b.user_id
  where (p_scope = 'mine' and b.user_id = auth.uid())
     or (p_scope = 'owner' and v.owner_id = auth.uid())
     or (p_scope = 'all' and public.is_manager())
  order by b.day desc, b.hour desc
  limit 300;
$$;
grant execute on function public.booking_list(text) to authenticated;

create or replace function public.fmt_hour(h int)
returns text language sql immutable as $$
  select (case when h % 24 = 0 then 12 when h % 24 > 12 then h % 24 - 12 else h % 24 end)::text
         || ':00' || case when h % 24 < 12 then 'ص' else 'م' end;
$$;

create or replace function public.set_booking_status(bid uuid, new_status text)
returns void language plpgsql security definer set search_path = public as $$
declare b public.bookings; is_owner boolean;
begin
  select * into b from public.bookings where id = bid;
  if not found then raise exception 'booking not found'; end if;
  select (exists(select 1 from public.venues v where v.id = b.venue_id and v.owner_id = auth.uid())
          or public.is_manager()) into is_owner;
  if new_status = 'cancelled' and b.status in ('pending', 'confirmed')
     and (b.user_id = auth.uid() or is_owner) then
    null;
  elsif new_status in ('confirmed', 'rejected') and b.status = 'pending' and is_owner then
    null;
  else
    raise exception 'not allowed';
  end if;
  update public.bookings set status = new_status where id = bid;
end; $$;
grant execute on function public.set_booking_status(uuid, text) to authenticated;

create or replace function public.trg_booking_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare v public.venues; who text; slot text;
begin
  select * into v from public.venues where id = new.venue_id;
  slot := v.name || ' · ' || to_char(new.day, 'DD/MM') || ' الساعة ' || public.fmt_hour(new.hour);
  select coalesce(nullif(name, ''), 'يوزر') into who from public.profiles where id = new.user_id;
  if tg_op = 'INSERT' then
    if v.owner_id is not null then
      insert into public.notifications (title, body, kind, user_id)
      values ('طلب حجز جديد 📅', who || ' عايز يحجز ' || slot, 'booking', v.owner_id);
    end if;
  elsif new.status is distinct from old.status then
    if new.status = 'confirmed' then
      insert into public.notifications (title, body, kind, user_id) values ('اتأكد حجزك ✅', slot, 'booking', new.user_id);
    elsif new.status = 'rejected' then
      insert into public.notifications (title, body, kind, user_id) values ('اترفض طلب الحجز ❌', slot, 'booking', new.user_id);
    elsif new.status = 'cancelled' then
      if auth.uid() = new.user_id and v.owner_id is not null then
        insert into public.notifications (title, body, kind, user_id)
        values ('اتلغى حجز 🚫', who || ' لغى ' || slot, 'booking', v.owner_id);
      elsif auth.uid() is distinct from new.user_id then
        insert into public.notifications (title, body, kind, user_id) values ('اتلغى حجزك 🚫', slot, 'booking', new.user_id);
      end if;
    end if;
  end if;
  return new;
end; $$;
drop trigger if exists booking_notify on public.bookings;
create trigger booking_notify after insert or update on public.bookings
for each row execute function public.trg_booking_notify();

-- ── تقييمات الملاعب (نجوم + تعليق) — أي يوزر ما عدا صاحب الملعب ──
create table if not exists public.venue_reviews (
  venue_id   uuid references public.venues(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  stars      int not null check (stars between 1 and 5),
  comment    text check (comment is null or length(comment) <= 500),
  created_at timestamptz not null default now(),
  primary key (venue_id, user_id)
);
alter table public.venue_reviews enable row level security;
drop policy if exists "reviews read" on public.venue_reviews;
create policy "reviews read" on public.venue_reviews for select to authenticated using (true);
drop policy if exists "reviews own write" on public.venue_reviews;
create policy "reviews own write" on public.venue_reviews for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid()
    and not exists (select 1 from public.venues v where v.id = venue_id and v.owner_id = auth.uid()));

-- متوسط تقييم كل ملعب
create or replace function public.venue_ratings()
returns table(venue_id uuid, avg numeric, count bigint)
language sql stable as $$
  select venue_id, round(avg(stars)::numeric, 1), count(*) from public.venue_reviews group by venue_id;
$$;
grant execute on function public.venue_ratings() to authenticated;

-- التقييمات بأسماء اللي كتبوها
create or replace function public.venue_review_list(p_venue uuid)
returns table(user_id uuid, name text, photo_url text, stars int, comment text, created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select r.user_id, p.name, p.photo_url, r.stars, r.comment, r.created_at
  from public.venue_reviews r join public.profiles p on p.id = r.user_id
  where r.venue_id = p_venue order by r.created_at desc limit 100;
$$;
grant execute on function public.venue_review_list(uuid) to authenticated;

create or replace function public.trg_review_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare v public.venues;
begin
  select * into v from public.venues where id = new.venue_id;
  if v.owner_id is not null and tg_op = 'INSERT' then
    insert into public.notifications (title, body, kind, user_id)
    values ('⭐ تقييم جديد لملعبك', v.name || ' · ' || repeat('★', new.stars) || coalesce(' — ' || left(new.comment, 80), ''),
            'booking', v.owner_id);
  end if;
  return new;
end $$;
drop trigger if exists review_notify on public.venue_reviews;
create trigger review_notify after insert on public.venue_reviews
for each row execute function public.trg_review_notify();

-- صور الملاعب: كل يوزر يرفع في فولدر باسمه (والمدير في أي حتة)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('venue-photos', 'venue-photos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "venue photos read" on storage.objects;
create policy "venue photos read" on storage.objects for select using (bucket_id = 'venue-photos');
drop policy if exists "venue photos manager upload" on storage.objects;
drop policy if exists "venue photos upload" on storage.objects;
create policy "venue photos upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'venue-photos'
    and (public.is_manager() or (storage.foldername(name))[1] = auth.uid()::text));
drop policy if exists "venue photos manager delete" on storage.objects;
drop policy if exists "venue photos delete" on storage.objects;
create policy "venue photos delete" on storage.objects for delete to authenticated
  using (bucket_id = 'venue-photos'
    and (public.is_manager() or (storage.foldername(name))[1] = auth.uid()::text));


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 10) SEASONS & CHIPS                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- الموسم: المدير بيحدد البداية ونص الموسم والنهاية.
create table if not exists public.seasons (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  starts_at  timestamptz not null,
  mid_at     timestamptz not null,
  ends_at    timestamptz not null,
  created_at timestamptz not null default now(),
  check (starts_at < mid_at and mid_at < ends_at)
);
alter table public.seasons enable row level security;
drop policy if exists "seasons read" on public.seasons;
create policy "seasons read" on public.seasons for select to authenticated using (true);
drop policy if exists "seasons manager write" on public.seasons;
create policy "seasons manager write" on public.seasons for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

create or replace function public.fn_season_at(ts timestamptz)
returns public.seasons language sql stable as $$
  select * from public.seasons where ts >= starts_at and ts < ends_at order by starts_at desc limit 1;
$$;

-- الكروت: triple (كابتن ×٣) · bench_boost (الاحتياطي يتحسب) · wildcard (تعدّل بعد القفل لحد البداية)
--          double (نقط التشكيلة كلها ×٢)
-- الحدود: triple/bench_boost/wildcard → مرتين في كل نص موسم · double → مرتين في الموسم كله.
-- كارت واحد بس في الجولة، على ماتش واحد، ومبيتلغيش.
create table if not exists public.chip_uses (
  user_id     uuid references public.profiles(id) on delete cascade,
  match_id    uuid references public.matches(id) on delete cascade,
  chip        text not null check (chip in ('triple', 'bench_boost', 'wildcard', 'double')),
  season_id   uuid not null references public.seasons(id) on delete cascade,
  half        int not null check (half in (1, 2)),
  week_cutoff timestamptz not null,
  created_at  timestamptz not null default now(),
  primary key (user_id, match_id),
  unique (user_id, week_cutoff)
);
alter table public.chip_uses enable row level security;
drop policy if exists "chips read" on public.chip_uses;
create policy "chips read" on public.chip_uses for select to authenticated
  using (user_id = auth.uid() or public.is_manager());
-- مفيش كتابة مباشرة (ولا حذف = مبيتلغيش): التفعيل بدالة activate_chip بس.

create or replace function public.fn_chip_limit(p_chip text)
returns int language sql immutable as $$ select 2; $$;

create or replace function public.fn_chip_name(p_chip text)
returns text language sql immutable as $$
  select case p_chip when 'triple' then 'كابتن ×٣' when 'bench_boost' then 'الاحتياطي يتحسب'
    when 'wildcard' then 'الوايلد كارد' when 'double' then 'الدبل ×٢' else p_chip end;
$$;

-- حالة الكروت لماتش معيّن (للشاشة): المستخدم، الحد، مفعّل هنا، وسبب المنع لو ممنوع.
create or replace function public.chip_status(p_match uuid)
returns table(chip text, used int, lim int, active boolean, blocked text)
language plpgsql stable security definer set search_path = public as $$
declare m public.matches; s public.seasons; h int; wc timestamptz; here text; round_used text;
        has_picks boolean;
begin
  select * into m from public.matches where id = p_match;
  if not found then return; end if;
  s := public.fn_season_at(m.date_time);
  wc := public.fn_week_cutoff(m.date_time);
  select c.chip into here from public.chip_uses c where c.user_id = auth.uid() and c.match_id = p_match;
  select c.chip into round_used from public.chip_uses c
    where c.user_id = auth.uid() and c.week_cutoff = wc and c.match_id <> p_match;
  has_picks := exists(select 1 from public.picks p where p.user_id = auth.uid() and p.match_id = p_match);
  if s.id is not null then
    h := case when m.date_time < s.mid_at then 1 else 2 end;
  end if;

  return query
  select k.chip,
    case when s.id is null then 0
         when k.chip = 'double' then (select count(*)::int from public.chip_uses c
              where c.user_id = auth.uid() and c.season_id = s.id and c.chip = 'double')
         else (select count(*)::int from public.chip_uses c
              where c.user_id = auth.uid() and c.season_id = s.id and c.chip = k.chip and c.half = h) end,
    public.fn_chip_limit(k.chip),
    here = k.chip,
    case
      when here is not null then (case when here = k.chip then null else 'فعّلت ' || public.fn_chip_name(here) || ' في الماتش ده' end)
      when s.id is null then 'مفيش موسم شغّال'
      when round_used is not null then 'استخدمت كارت في الجولة دي'
      when m.status <> 'upcoming' then 'الماتش خلص'
      when k.chip = 'wildcard' and now() >= m.date_time then 'الماتش بدأ'
      when k.chip <> 'wildcard' and now() >= m.date_time - interval '1 hour' then 'التشكيلة اتقفلت'
      when not has_picks then 'احفظ تشكيلتك الأول'
      else null end
  from (values ('triple'), ('bench_boost'), ('wildcard'), ('double')) as k(chip);
end $$;
grant execute on function public.chip_status(uuid) to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 11) CHALLENGE — توقّع النتيجة                                   ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.predictions (
  user_id    uuid references public.profiles(id) on delete cascade,
  match_id   uuid references public.matches(id) on delete cascade,
  score_a    int not null check (score_a between 0 and 99),
  score_b    int not null check (score_b between 0 and 99),
  created_at timestamptz not null default now(),
  primary key (user_id, match_id)
);
create index if not exists predictions_match on public.predictions(match_id);
alter table public.predictions enable row level security;

-- توقعات الناس تبان بعد ما الماتش يبدأ بس
drop policy if exists "predictions read" on public.predictions;
create policy "predictions read" on public.predictions for select to authenticated using (
  user_id = auth.uid() or public.is_manager()
  or exists (select 1 from public.matches m where m.id = match_id and m.date_time <= now())
);
drop policy if exists "predictions own write" on public.predictions;
create policy "predictions own write" on public.predictions for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and exists (
    select 1 from public.matches m where m.id = match_id and m.is_challenge
      and m.status = 'upcoming' and now() < m.date_time - interval '1 hour'));

-- (مدير) يعلن ماتش تحدّي الجولة
create or replace function public.set_challenge(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  select * into m from public.matches where id = p_match;
  if not found or m.status <> 'upcoming' then raise exception 'اختار ماتش لسه ملعبش'; end if;
  update public.matches set is_challenge = true where id = p_match;
  insert into public.notifications (title, body, kind, match_id)
  values ('🎯 تحدّي الجولة', 'توقّع نتيجة ' || m.teams[1] || ' ضد ' || m.teams[2] || ' صح واكسب +٥ نقط', 'challenge', p_match);
end $$;
grant execute on function public.set_challenge(uuid) to authenticated;

-- ملخص التوقعات بعد الماتش: كام واحد توقّع، وكام جابها صح
create or replace function public.challenge_summary(p_match uuid)
returns table(total bigint, correct bigint)
language sql stable security definer set search_path = public as $$
  select count(*), count(*) filter (where p.score_a = m.score_a and p.score_b = m.score_b)
  from public.predictions p join public.matches m on m.id = p.match_id where p.match_id = p_match;
$$;
grant execute on function public.challenge_summary(uuid) to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 12) FOLLOWS — متابعة ماتش لايف                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.match_follows (
  user_id    uuid references public.profiles(id) on delete cascade,
  match_id   uuid references public.matches(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, match_id)
);
create index if not exists follows_match on public.match_follows(match_id);
alter table public.match_follows enable row level security;
drop policy if exists "follows own" on public.match_follows;
create policy "follows own" on public.match_follows for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- الحد: ٣ ماتشات بس في اليوم (بيوم الماتش بتوقيت القاهرة)، ومش ماتش خلص.
create or replace function public.trg_follow_limit()
returns trigger language plpgsql security definer set search_path = public as $$
declare m public.matches; n int;
begin
  select * into m from public.matches where id = new.match_id;
  if not found then raise exception 'الماتش مش موجود'; end if;
  if m.status = 'finished' then raise exception 'الماتش ده خلص'; end if;
  select count(*) into n from public.match_follows f join public.matches x on x.id = f.match_id
  where f.user_id = new.user_id
    and (x.date_time at time zone 'Africa/Cairo')::date = (m.date_time at time zone 'Africa/Cairo')::date;
  if n >= 3 then raise exception 'آخرك ٣ ماتشات تتابعها في اليوم'; end if;
  return new;
end $$;
drop trigger if exists follow_limit on public.match_follows;
create trigger follow_limit before insert on public.match_follows
for each row execute function public.trg_follow_limit();

-- قراءة الإشعارات: الكل + الموجّهة ليك + أحداث الماتشات اللي بتتابعها
drop policy if exists "notifications read" on public.notifications;
create policy "notifications read" on public.notifications for select to authenticated using (
  audience = 'all'
  or (audience = 'user' and user_id = auth.uid())
  or (audience = 'match' and exists (select 1 from public.match_follows f
        where f.match_id = notifications.match_id and f.user_id = auth.uid()))
);

-- كل حدث بيتسجّل → إشعار لمتابعين الماتش
create or replace function public.trg_event_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare m public.matches; pn text;
begin
  select * into m from public.matches where id = new.match_id;
  select name into pn from public.players where id = new.player_id;
  insert into public.notifications (title, body, kind, match_id, audience)
  values (public.fn_event_label(new.type) || ' — ' || coalesce(pn, ''),
          m.teams[1] || ' ضد ' || m.teams[2] || coalesce(' · الدقيقة ' || new.minute, ''),
          'event', new.match_id, 'match');
  return new;
end $$;
drop trigger if exists event_notify on public.events;
create trigger event_notify after insert on public.events
for each row execute function public.trg_event_notify();


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 13) RATINGS — تقييم الجمهور + رجل المباراة                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- وقت انتهاء الماتش بيتسجّل لوحده (التقييم مفتوح ٢٤ ساعة بعده)
create or replace function public.trg_match_finished_at()
returns trigger language plpgsql as $$
begin
  if new.status = 'finished' and old.status is distinct from 'finished' then
    new.finished_at := now();
  elsif new.status <> 'finished' then
    new.finished_at := null;
  end if;
  return new;
end $$;
drop trigger if exists match_finished_at on public.matches;
create trigger match_finished_at before update on public.matches
for each row execute function public.trg_match_finished_at();

create table if not exists public.player_ratings (
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  rating     int not null check (rating between 1 and 10),
  created_at timestamptz not null default now(),
  primary key (match_id, player_id, user_id)
);
alter table public.player_ratings enable row level security;

create or replace function public.fn_rating_open(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.matches m where m.id = p_match and m.status = 'finished'
    and m.finished_at is not null and m.finished_at > now() - interval '24 hours' and not m.motm_done);
$$;

drop policy if exists "ratings read own" on public.player_ratings;
create policy "ratings read own" on public.player_ratings for select to authenticated
  using (user_id = auth.uid() or public.is_manager());
drop policy if exists "ratings own write" on public.player_ratings;
create policy "ratings own write" on public.player_ratings for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and public.fn_rating_open(match_id)
    and exists (select 1 from public.lineups l where l.match_id = player_ratings.match_id
                and l.player_id = player_ratings.player_id));

-- متوسط تقييم كل لاعب في الماتش + عدد الأصوات + تقييمك
create or replace function public.match_rating_summary(p_match uuid)
returns table(player_id uuid, avg numeric, votes bigint, mine int)
language sql stable security definer set search_path = public as $$
  select l.player_id,
    round(avg(r.rating)::numeric, 1),
    count(r.user_id),
    max(r.rating) filter (where r.user_id = auth.uid())
  from public.lineups l
  left join public.player_ratings r on r.match_id = l.match_id and r.player_id = l.player_id
  where l.match_id = p_match
  group by l.player_id;
$$;
grant execute on function public.match_rating_summary(uuid) to authenticated;

-- بعد ٢٤ ساعة: أعلى تقييم = رجل المباراة → حدث motm (+٣) + إشعار
create or replace function public.fn_close_ratings()
returns void language plpgsql security definer set search_path = public as $$
declare r record; w uuid; wn text;
begin
  for r in select id, teams from public.matches
           where status = 'finished' and not motm_done and finished_at is not null
             and finished_at <= now() - interval '24 hours' loop
    w := null;
    select pr.player_id into w from public.player_ratings pr where pr.match_id = r.id
      group by pr.player_id order by avg(pr.rating) desc, count(*) desc limit 1;
    update public.matches set motm_done = true, motm_player_id = w where id = r.id;
    if w is not null then
      select name into wn from public.players where id = w;
      insert into public.events (match_id, player_id, type) values (r.id, w, 'motm');
      insert into public.notifications (title, body, kind, match_id)
      values ('⭐ رجل المباراة: ' || wn, r.teams[1] || ' ضد ' || r.teams[2] || ' · +٣ نقط بتصويت الجمهور', 'match', r.id);
    end if;
  end loop;
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 14) PLAYER CLAIMS — اللاعب يوثّق بروفايله                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.player_claims (
  id          uuid primary key default gen_random_uuid(),
  player_id   uuid not null references public.players(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  status      text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  note        text check (note is null or length(note) <= 300),
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz
);
create unique index if not exists claims_one_pending on public.player_claims(user_id) where status = 'pending';
alter table public.player_claims enable row level security;
drop policy if exists "claims read" on public.player_claims;
create policy "claims read" on public.player_claims for select to authenticated
  using (user_id = auth.uid() or public.is_manager());
drop policy if exists "claims request" on public.player_claims;
create policy "claims request" on public.player_claims for insert to authenticated with check (
  user_id = auth.uid() and status = 'pending'
  and not exists (select 1 from public.players p where p.id = player_id and p.user_id is not null)
  and not exists (select 1 from public.players p where p.user_id = auth.uid())
);

-- طلب جديد → إشعار لكل المديرين
create or replace function public.trg_claim_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare pn text; un text;
begin
  select name into pn from public.players where id = new.player_id;
  select name into un from public.profiles where id = new.user_id;
  insert into public.notifications (title, body, kind, user_id)
  select '🪪 طلب توثيق لاعب', coalesce(un, 'يوزر') || ' بيقول إنه ' || coalesce(pn, ''), 'status', p.id
  from public.profiles p where p.role = 'manager';
  return new;
end $$;
drop trigger if exists claim_notify on public.player_claims;
create trigger claim_notify after insert on public.player_claims
for each row execute function public.trg_claim_notify();

-- (مدير) موافقة/رفض
create or replace function public.review_claim(p_claim uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
declare c public.player_claims; pn text;
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  select * into c from public.player_claims where id = p_claim;
  if not found or c.status <> 'pending' then raise exception 'الطلب مش موجود أو اتراجع'; end if;
  select name into pn from public.players where id = c.player_id;
  if p_approve then
    if exists (select 1 from public.players where id = c.player_id and user_id is not null) then
      raise exception 'اللاعب ده موثّق لحد تاني';
    end if;
    update public.players set user_id = c.user_id where id = c.player_id;
    update public.player_claims set status = 'approved', reviewed_at = now() where id = c.id;
    update public.player_claims set status = 'rejected', reviewed_at = now()
      where player_id = c.player_id and status = 'pending' and id <> c.id;
    insert into public.notifications (title, body, kind, user_id)
    values ('✓ اتوثّق بروفايلك', 'بقيت ' || pn || ' رسميًا — افتح "أنا كلاعب" وشوف مين اختارك', 'status', c.user_id);
  else
    update public.player_claims set status = 'rejected', reviewed_at = now() where id = c.id;
    insert into public.notifications (title, body, kind, user_id)
    values ('طلب التوثيق اترفض', 'المدير مقدرش يأكّد إنك ' || pn, 'status', c.user_id);
  end if;
end $$;
grant execute on function public.review_claim(uuid, boolean) to authenticated;

-- (مدير) فك التوثيق
create or replace function public.unlink_player(p_player uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  update public.players set user_id = null where id = p_player;
end $$;
grant execute on function public.unlink_player(uuid) to authenticated;

-- الطلبات المعلّقة بالأسماء (للمدير)
create or replace function public.pending_claims()
returns table(id uuid, player_id uuid, player_name text, team text, user_id uuid, user_name text,
              phone text, note text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  return query select c.id, c.player_id, pl.name, pl.team, c.user_id, pr.name, pr.phone, c.note, c.created_at
    from public.player_claims c join public.players pl on pl.id = c.player_id
    join public.profiles pr on pr.id = c.user_id
    where c.status = 'pending' order by c.created_at;
end $$;
grant execute on function public.pending_claims() to authenticated;


-- "أنا كلاعب": كام واحد اختارك وخلّاك كابتن في الجولة + امتلاكك وترتيبك في مركزك
-- + النقط اللي جبتها لليوزرز من أول الموسم (الأساسي بس، والكابتن ×٢)
create or replace function public.player_fan_stats(p_player uuid, p_from timestamptz, p_to timestamptz)
returns table(owners bigint, captains bigint, managers bigint, ownership numeric,
              pos_rank bigint, pos_total bigint, points_for_users bigint)
language sql stable security definer set search_path = public as $$
  with w as (select * from public.player_window_stats(p_from, p_to)),
  me as (select * from w where w.id = p_player),
  pos as (select w.id, w.ownership from w join public.players pl on pl.id = w.id
          where pl.position = (select position from public.players where id = p_player)),
  since as (select coalesce((public.fn_season_at(now())).starts_at, '-infinity'::timestamptz) as t)
  select me.owners,
    (select count(distinct p.user_id) from public.picks p join public.matches m on m.id = p.match_id
     where p.player_id = p_player and p.is_captain and m.date_time > p_from and m.date_time <= p_to),
    me.managers, me.ownership,
    (select count(*) + 1 from pos where pos.ownership > me.ownership),
    (select count(*) from pos),
    (select coalesce(sum(x.base * case when p.is_captain then 2 else 1 end), 0)
     from public.picks p
     join (select e.match_id, sum(public.fn_event_points(e.type, pl.position)) as base
           from public.events e join public.players pl on pl.id = e.player_id
           join public.matches m on m.id = e.match_id
           where e.player_id = p_player and m.date_time >= (select t from since)
           group by e.match_id) x on x.match_id = p.match_id
     where p.player_id = p_player and p.status = 'starting')::bigint
  from me;
$$;
grant execute on function public.player_fan_stats(uuid, timestamptz, timestamptz) to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 15) SCORING v2 — النقاط بالكروت والبونص + حفظ التشكيلة          ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- نقط كل يوزر في كل ماتش (مخزّنة عشان الترتيب والإنجازات يبقوا سريعين)
create table if not exists public.user_match_points (
  user_id  uuid references public.profiles(id) on delete cascade,
  match_id uuid references public.matches(id) on delete cascade,
  points   int not null default 0,
  primary key (user_id, match_id)
);
create index if not exists ump_match on public.user_match_points(match_id);
alter table public.user_match_points enable row level security;
drop policy if exists "ump read" on public.user_match_points;
create policy "ump read" on public.user_match_points for select to authenticated using (true);

-- نقط تشكيلة يوزر في ماتش (نفس MatchPoints في Dart بالظبط):
--   الأساسيين بس (إلا مع bench_boost الكل) · الكابتن ×٢ لو لعب، ولو ملعبش النائب ×٢
--   triple → المضاعف ×٣ · double → المجموع كله ×٢
create or replace function public.fn_user_match_points(p_user uuid, p_match uuid)
returns int language sql stable security definer set search_path = public as $$
  with chip as (
    select coalesce((select c.chip from public.chip_uses c
                     where c.user_id = p_user and c.match_id = p_match), '') as c
  ), pts as (
    select pk.status, pk.is_captain, pk.is_vice,
      coalesce((select sum(public.fn_event_points(e.type, pl.position)) from public.events e
                where e.player_id = pk.player_id and e.match_id = p_match), 0) as base,
      exists (select 1 from public.events e where e.player_id = pk.player_id and e.match_id = p_match) as played
    from public.picks pk join public.players pl on pl.id = pk.player_id
    where pk.user_id = p_user and pk.match_id = p_match
  ), cap as (
    select coalesce(bool_or(is_captain and played), false) as cap_played from pts
  )
  select (coalesce(sum(
      pts.base * case
        when (pts.is_captain and cap.cap_played) or (pts.is_vice and not cap.cap_played)
          then case when (select c from chip) = 'triple' then 3 else 2 end
        else 1 end
    ) filter (where pts.status = 'starting' or (select c from chip) = 'bench_boost'), 0)
    * case when (select c from chip) = 'double' then 2 else 1 end)::int
  from pts cross join cap;
$$;

-- بونص التوقعات الصح (+٥ لكل واحدة)
create or replace function public.fn_user_bonus(p_user uuid)
returns int language sql stable security definer set search_path = public as $$
  select (5 * count(*))::int from public.predictions pr join public.matches m on m.id = pr.match_id
  where pr.user_id = p_user and m.is_challenge and m.status = 'finished'
    and pr.score_a = m.score_a and pr.score_b = m.score_b;
$$;

-- إجمالي نقاط اليوزر = نقط الماتشات + البونص
create or replace function public.fn_user_points(p_user uuid)
returns int language sql stable security definer set search_path = public as $$
  select (coalesce((select sum(points) from public.user_match_points where user_id = p_user), 0)
          + public.fn_user_bonus(p_user))::int;
$$;

create or replace function public.fn_recalc_user_match(p_user uuid, p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.picks where user_id = p_user and match_id = p_match) then
    insert into public.user_match_points (user_id, match_id, points)
    values (p_user, p_match, public.fn_user_match_points(p_user, p_match))
    on conflict (user_id, match_id) do update set points = excluded.points;
  else
    delete from public.user_match_points where user_id = p_user and match_id = p_match;
  end if;
  update public.profiles set total_points = public.fn_user_points(p_user), badges_dirty = true
  where id = p_user;
end $$;

create or replace function public.fn_recalc_match(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.user_match_points (user_id, match_id, points)
  select u.user_id, p_match, public.fn_user_match_points(u.user_id, p_match)
  from (select distinct user_id from public.picks where match_id = p_match) u
  on conflict (user_id, match_id) do update set points = excluded.points;
  delete from public.user_match_points
  where match_id = p_match and user_id not in (select user_id from public.picks where match_id = p_match);
  update public.profiles set total_points = public.fn_user_points(id), badges_dirty = true
  where id in (select distinct user_id from public.picks where match_id = p_match);
end $$;

-- إعادة حساب الكل (يدوي من SQL Editor)
create or replace function public.fn_recalc_users()
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.user_match_points (user_id, match_id, points)
  select u.user_id, u.match_id, public.fn_user_match_points(u.user_id, u.match_id)
  from (select distinct user_id, match_id from public.picks) u
  on conflict (user_id, match_id) do update set points = excluded.points;
  delete from public.user_match_points ump where not exists (
    select 1 from public.picks p where p.user_id = ump.user_id and p.match_id = ump.match_id);
  update public.profiles set total_points = public.fn_user_points(id) where id is not null;
end $$;

-- أي تغيير في الأحداث → إحصائيات اللاعب + نقط اليوزرز في الماتش ده بس
create or replace function public.trg_events_recalc()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.fn_recalc_player(old.player_id);
    perform public.fn_recalc_match(old.match_id);
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.fn_recalc_player(new.player_id);
    if tg_op = 'INSERT' or new.match_id is distinct from old.match_id then
      perform public.fn_recalc_match(new.match_id);
    end if;
  end if;
  return null;
end $$;
drop trigger if exists events_recalc on public.events;
create trigger events_recalc after insert or update or delete on public.events
for each row execute function public.trg_events_recalc();

-- الماتش خلص/النتيجة اتغيّرت → بونص التوقعات + إشعار للي توقّعوا صح
create or replace function public.trg_match_result()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.is_challenge and (new.status, new.score_a, new.score_b, new.is_challenge)
       is distinct from (old.status, old.score_a, old.score_b, old.is_challenge) then
    update public.profiles set total_points = public.fn_user_points(id), badges_dirty = true
    where id in (select user_id from public.predictions where match_id = new.id);
    if new.status = 'finished' and old.status is distinct from 'finished' then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🎯 توقّعك صح! +٥', new.teams[1] || ' ' || new.score_a || ' - ' || new.score_b || ' ' || new.teams[2],
             'challenge', p.user_id, new.id
      from public.predictions p
      where p.match_id = new.id and p.score_a = new.score_a and p.score_b = new.score_b;
    end if;
  end if;
  return null;
end $$;
drop trigger if exists match_result on public.matches;
create trigger match_result after update on public.matches
for each row execute function public.trg_match_result();

-- هل اليوزر يقدر يعدّل تشكيلته دلوقتي؟ قبل الديدلاين (ساعة قبل الماتش)،
-- أو بالوايلد كارد لحد ما الماتش يبدأ.
create or replace function public.fn_can_edit_picks(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.matches m where m.id = p_match and m.status = 'upcoming' and (
    now() < m.date_time - interval '1 hour'
    or (now() < m.date_time and exists (select 1 from public.chip_uses c
          where c.user_id = auth.uid() and c.match_id = p_match and c.chip = 'wildcard'))));
$$;

-- حفظ التشكيلة (استبدال كامل في transaction واحدة) + التحقّق من القواعد في السيرفر:
-- ٥ أساسيين (حارس + ٢ من كل فريق) + ٢ احتياطي + كابتن من الأساسيين + نائب اختياري.
-- p_picks = [{player_id, status, is_captain, is_vice}, ...]
create or replace function public.save_picks(p_match uuid, p_picks jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); m public.matches;
        n_start int; n_bench int; n_gk int; n_a int; n_b int; n_cap int; n_vice int; n_bad int; n_dup int;
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  select * into m from public.matches where id = p_match;
  if not found then raise exception 'الماتش مش موجود'; end if;
  if not public.fn_can_edit_picks(p_match) then raise exception 'التشكيلة اتقفلت — عدّى الديدلاين'; end if;
  if jsonb_typeof(p_picks) <> 'array' then raise exception 'بيانات غلط'; end if;

  with sel as (
    select * from jsonb_to_recordset(p_picks) as x(player_id uuid, status text, is_captain boolean, is_vice boolean)
  ), j as (
    select s.player_id, s.status, coalesce(s.is_captain, false) cap, coalesce(s.is_vice, false) vic,
           pl.position, pl.team, l.status as lstatus
    from sel s
    left join public.players pl on pl.id = s.player_id
    left join public.lineups l on l.match_id = p_match and l.player_id = s.player_id
  )
  select count(*) filter (where status = 'starting'),
         count(*) filter (where status = 'bench'),
         count(*) filter (where status = 'starting' and position = 'GK'),
         count(*) filter (where status = 'starting' and position <> 'GK' and team = m.teams[1]),
         count(*) filter (where status = 'starting' and position <> 'GK' and team = m.teams[2]),
         count(*) filter (where cap),
         count(*) filter (where vic),
         count(*) filter (where lstatus is null or status not in ('starting', 'bench')
                          or ((cap or vic) and status <> 'starting') or (cap and vic)),
         count(*) - count(distinct player_id)
  into n_start, n_bench, n_gk, n_a, n_b, n_cap, n_vice, n_bad, n_dup
  from j;

  if n_bad > 0 or n_dup > 0 then raise exception 'فيه لاعب مش في تشكيلة الماتش — حدّث الصفحة'; end if;
  if n_gk <> 1 then raise exception 'لازم حارس واحد أساسي'; end if;
  if n_a <> 2 then raise exception 'لازم ٢ أساسيين من %', m.teams[1]; end if;
  if n_b <> 2 then raise exception 'لازم ٢ أساسيين من %', m.teams[2]; end if;
  if n_start <> 5 then raise exception 'لازم ٥ أساسيين بالظبط'; end if;
  if n_bench <> 2 then raise exception 'لازم ٢ احتياطي'; end if;
  if n_cap <> 1 then raise exception 'اختار كابتن واحد من الأساسيين'; end if;
  if n_vice > 1 then raise exception 'كابتن احتياطي واحد بس'; end if;

  delete from public.picks where user_id = u and match_id = p_match;
  insert into public.picks (user_id, match_id, player_id, status, is_captain, is_vice, saved_at)
  select u, p_match, x.player_id, x.status, coalesce(x.is_captain, false), coalesce(x.is_vice, false), now()
  from jsonb_to_recordset(p_picks) as x(player_id uuid, status text, is_captain boolean, is_vice boolean);
  perform public.fn_recalc_user_match(u, p_match);
end $$;
grant execute on function public.save_picks(uuid, jsonb) to authenticated;

-- تفعيل كارت (مبيتلغيش)
create or replace function public.activate_chip(p_match uuid, p_chip text)
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); m public.matches; s public.seasons; h int; wc timestamptz; used int;
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  if p_chip not in ('triple', 'bench_boost', 'wildcard', 'double') then raise exception 'كارت مش معروف'; end if;
  perform pg_advisory_xact_lock(hashtext(u::text));
  select * into m from public.matches where id = p_match;
  if not found or m.status <> 'upcoming' then raise exception 'الماتش مش متاح'; end if;
  if p_chip = 'wildcard' then
    if now() >= m.date_time then raise exception 'الماتش بدأ'; end if;
  elsif now() >= m.date_time - interval '1 hour' then
    raise exception 'التشكيلة اتقفلت — الكارت لازم يتفعّل قبل الديدلاين';
  end if;
  if not exists (select 1 from public.picks where user_id = u and match_id = p_match) then
    raise exception 'احفظ تشكيلتك في الماتش ده الأول';
  end if;
  s := public.fn_season_at(m.date_time);
  if s.id is null then raise exception 'مفيش موسم شغّال — المدير لازم يحدّد مواعيد الموسم'; end if;
  h := case when m.date_time < s.mid_at then 1 else 2 end;
  wc := public.fn_week_cutoff(m.date_time);
  if exists (select 1 from public.chip_uses where user_id = u and match_id = p_match) then
    raise exception 'فعّلت كارت في الماتش ده بالفعل';
  end if;
  if exists (select 1 from public.chip_uses where user_id = u and week_cutoff = wc) then
    raise exception 'استخدمت كارت في الجولة دي — كارت واحد بس في الجولة';
  end if;
  if p_chip = 'double' then
    select count(*) into used from public.chip_uses where user_id = u and season_id = s.id and chip = 'double';
    if used >= public.fn_chip_limit(p_chip) then raise exception 'الدبل خلص — مرتين بس في الموسم'; end if;
  else
    select count(*) into used from public.chip_uses
    where user_id = u and season_id = s.id and chip = p_chip and half = h;
    if used >= public.fn_chip_limit(p_chip) then
      raise exception '% خلص — مرتين بس في النص ده من الموسم', public.fn_chip_name(p_chip);
    end if;
  end if;
  insert into public.chip_uses (user_id, match_id, chip, season_id, half, week_cutoff)
  values (u, p_match, p_chip, s.id, h, wc);
  perform public.fn_recalc_user_match(u, p_match);
end $$;
grant execute on function public.activate_chip(uuid, text) to authenticated;

select public.fn_recalc_users();


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 16) LEAGUES — أي يوزر يعمل دوري                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- الدوري يبان لأعضائه وصاحبه والمدير (والعام للكل) — الأكواد متتسرّبش.
drop policy if exists "leagues read" on public.leagues;
create policy "leagues read" on public.leagues for select to authenticated using (
  type in ('public', 'global') or owner_id = auth.uid() or public.is_manager()
  or exists (select 1 from public.league_members lm where lm.league_id = leagues.id and lm.user_id = auth.uid())
);
drop policy if exists "leagues insert" on public.leagues;
create policy "leagues insert" on public.leagues for insert to authenticated with check (
  owner_id = auth.uid() and type <> 'global'
  and (public.is_manager() or (select count(*) from public.leagues l where l.owner_id = auth.uid()) < 10)
);
drop policy if exists "leagues manager delete" on public.leagues;
drop policy if exists "leagues delete" on public.leagues;
create policy "leagues delete" on public.leagues for delete to authenticated
  using (owner_id = auth.uid() or public.is_manager());
drop policy if exists "leagues update" on public.leagues;
create policy "leagues update" on public.leagues for update to authenticated
  using (owner_id = auth.uid() or public.is_manager())
  with check ((owner_id = auth.uid() and type <> 'global') or public.is_manager());
-- الخروج من دوري: العضو نفسه، أو صاحب الدوري يطرده، أو المدير
create policy "members delete" on public.league_members for delete to authenticated using (
  auth.uid() = user_id or public.is_manager()
  or exists (select 1 from public.leagues l where l.id = league_id and l.owner_id = auth.uid())
);

-- الانضمام بالكود
create or replace function public.join_league(p_code text)
returns uuid language plpgsql security definer set search_path = public as $$
declare lid uuid;
begin
  if auth.uid() is null then raise exception 'سجّل دخولك الأول'; end if;
  select id into lid from public.leagues where invite_code = upper(trim(p_code));
  if lid is null then raise exception 'كود غير صحيح'; end if;
  if (select count(*) from public.league_members where league_id = lid) >= 500 then
    raise exception 'الدوري ده مليان';
  end if;
  insert into public.league_members (league_id, user_id) values (lid, auth.uid())
  on conflict do nothing;
  update public.profiles set badges_dirty = true
  where id = (select owner_id from public.leagues where id = lid);
  return lid;
end $$;
grant execute on function public.join_league(text) to authenticated;

-- دورياتي في طلب واحد: العام + اللي أنا عضو فيها، بعدد الأعضاء وترتيبي في كل واحد
create or replace function public.my_leagues()
returns table(id uuid, name text, type text, invite_code text, owner_id uuid, member_count bigint, my_rank bigint)
language sql stable security definer set search_path = public as $$
  with me as (select * from public.profiles where id = auth.uid()),
  mine as (
    select l.id, l.name, l.type, l.invite_code, l.owner_id from public.leagues l where l.type = 'global'
    union
    select l.id, l.name, l.type, l.invite_code, l.owner_id from public.leagues l
    join public.league_members m on m.league_id = l.id
    where m.user_id = auth.uid() and l.type <> 'global'
  )
  select mine.id, mine.name, mine.type, mine.invite_code, mine.owner_id,
    case when mine.type = 'global' then (select count(*) from public.profiles)
         else (select count(*) from public.league_members m where m.league_id = mine.id) end,
    1 + (select count(*) from public.profiles p, me
         where (mine.type = 'global'
                or p.id in (select m.user_id from public.league_members m where m.league_id = mine.id))
           and (p.total_points, p.low_picks, -p.avg_own) > (me.total_points, me.low_picks, -me.avg_own))
  from mine
  order by (mine.type = 'global') desc, mine.name;
$$;
grant execute on function public.my_leagues() to authenticated;

-- (مدير) كل الدوريات بأصحابها وعدد الأعضاء
create or replace function public.admin_leagues()
returns table(id uuid, name text, type text, invite_code text, owner_id uuid, owner_name text,
              members bigint, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  return query select l.id, l.name, l.type, l.invite_code, l.owner_id, p.name,
    (select count(*) from public.league_members m where m.league_id = l.id), l.created_at
    from public.leagues l left join public.profiles p on p.id = l.owner_id
    order by l.created_at desc;
end $$;
grant execute on function public.admin_leagues() to authenticated;


-- ── الدوري العام: فيه كل اليوزرز أوتوماتيك (المدير بيعمله — واحد بس) ──
create unique index if not exists leagues_one_global on public.leagues(type) where type = 'global';

create or replace function public.create_global_league(p_name text)
returns uuid language plpgsql security definer set search_path = public as $$
declare lid uuid;
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  if exists (select 1 from public.leagues where type = 'global') then raise exception 'الدوري العام موجود بالفعل'; end if;
  insert into public.leagues (name, type, owner_id)
  values (coalesce(nullif(trim(p_name), ''), 'دوري الخماسي العام'), 'global', auth.uid())
  returning id into lid;
  insert into public.notifications (title, body, kind)
  values ('🏆 الدوري العام بدأ', 'كل اليوزرز فيه أوتوماتيك — شوف ترتيبك في تاب الدوريات', 'match');
  return lid;
end $$;
grant execute on function public.create_global_league(text) to authenticated;

-- كسر التعادل: كام لاعب أساسي اخترته وامتلاكه في الماتش كان أقل من ٢٥٪ (الأكتر فوق)،
-- ولو لسه متعادلين: متوسط امتلاك اختياراتك الأقل فوق. (الماتشات اللي قفلت بس)
create or replace function public.fn_user_tiebreak()
returns table(user_id uuid, low_picks bigint, avg_own numeric)
language sql stable security definer set search_path = public as $$
  with locked as (
    select id from public.matches where date_time - interval '1 hour' <= now()
  ), tot as (
    select p.match_id, count(distinct p.user_id)::numeric as n from public.picks p
    where p.match_id in (select id from locked) group by p.match_id
  ), own as (
    select p.match_id, p.player_id, count(distinct p.user_id)::numeric as n from public.picks p
    where p.match_id in (select id from locked) group by p.match_id, p.player_id
  ), mine as (
    select p.user_id, own.n * 100 / tot.n as pct
    from public.picks p
    join tot on tot.match_id = p.match_id
    join own on own.match_id = p.match_id and own.player_id = p.player_id
    where p.status = 'starting'
  )
  select mine.user_id, count(*) filter (where mine.pct < 25), round(avg(mine.pct), 1)
  from mine group by mine.user_id;
$$;

-- بيتنادي من fn_tick لما ماتشات تبدأ: يحدّث كسر التعادل لليوزرز اللي لعبوا فيها بس
create or replace function public.fn_update_tiebreak()
returns void language plpgsql security definer set search_path = public as $$
declare ids uuid[];
begin
  select array_agg(id) into ids from public.matches where not tiebreak_done and date_time <= now();
  if ids is null then return; end if;
  update public.matches set tiebreak_done = true where id = any(ids);
  update public.profiles p set low_picks = t.low_picks, avg_own = t.avg_own
  from public.fn_user_tiebreak() t
  where p.id = t.user_id
    and p.id in (select distinct pk.user_id from public.picks pk where pk.match_id = any(ids));
end $$;

-- ترتيب دوري: النقط ثم كسر التعادل (المتعادلين بالظبط لهم نفس المركز). العام = كل اليوزرز.
drop function if exists public.league_standings(uuid);
create or replace function public.league_standings(p_league uuid)
returns table(rank bigint, user_id uuid, name text, photo_url text, points int, low_picks int)
language plpgsql stable security definer set search_path = public as $$
declare l public.leagues;
begin
  select * into l from public.leagues where id = p_league;
  if not found then return; end if;
  if not (l.type in ('public', 'global') or l.owner_id = auth.uid() or public.is_manager()
          or exists (select 1 from public.league_members m where m.league_id = l.id and m.user_id = auth.uid())) then
    raise exception 'مش عضو في الدوري ده';
  end if;
  return query
  select rank() over (order by p.total_points desc, p.low_picks desc, p.avg_own asc),
         p.id, p.name, p.photo_url, p.total_points, p.low_picks
  from public.profiles p
  where l.type = 'global'
     or p.id in (select m.user_id from public.league_members m where m.league_id = l.id)
  order by p.total_points desc, p.low_picks desc, p.avg_own asc, p.created_at
  limit 500;
end $$;
grant execute on function public.league_standings(uuid) to authenticated;

-- ترتيبي العام = كام واحد أحسن مني + ١
create or replace function public.my_global_rank()
returns bigint language sql stable security definer set search_path = public as $$
  select 1 + count(*) from public.profiles p, public.profiles me
  where me.id = auth.uid()
    and (p.total_points, p.low_picks, -p.avg_own) > (me.total_points, me.low_picks, -me.avg_own);
$$;
grant execute on function public.my_global_rank() to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 17) AWARDS & TEAM OF THE WEEK                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- الفايز في تصويت = أكتر أصوات (التعادل: الأقدم)
create or replace function public.fn_poll_winner(p_poll uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select o.id from public.poll_options o left join public.poll_votes v on v.option_id = o.id
  where o.poll_id = p_poll group by o.id
  having count(v.user_id) > 0
  order by count(v.user_id) desc, min(o.id::text) limit 1;
$$;

-- (مدير) هدف/تصدّي الموسم: المرشّحين = كل اللي كسبوا هدف/تصدّي الجولة في الموسم الحالي
create or replace function public.create_season_award(p_kind text)
returns uuid language plpgsql security definer set search_path = public as $$
declare s public.seasons; pid uuid; n int;
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  if p_kind not in ('goal', 'save') then raise exception 'نوع غلط'; end if;
  s := public.fn_season_at(now());
  if s.id is null then
    select * into s from public.seasons order by ends_at desc limit 1;
  end if;
  if s.id is null then raise exception 'مفيش موسم متسجّل'; end if;
  update public.polls set active = false where kind = p_kind || '_season' and active;
  insert into public.polls (kind, question, active)
  values (p_kind || '_season', case when p_kind = 'goal' then 'هدف الموسم 🏆' else 'تصدّي الموسم 🏆' end, true)
  returning id into pid;
  insert into public.poll_options (poll_id, label, player_id, video_url, match_id)
  select pid, o.label, o.player_id, o.video_url, o.match_id
  from public.polls p join public.poll_options o on o.id = public.fn_poll_winner(p.id)
  where p.kind = p_kind || '_week' and not p.active
    and p.created_at >= s.starts_at and p.created_at < s.ends_at;
  get diagnostics n = row_count;
  if n < 2 then raise exception 'محتاج فايزين اتنين على الأقل من جولات الموسم'; end if;
  insert into public.notifications (title, body, kind)
  values (case when p_kind = 'goal' then '🏆 تصويت هدف الموسم' else '🏆 تصويت تصدّي الموسم' end,
          'اتفرّج على أحلى ' || n || ' واختار الأحسن', 'vote');
  return pid;
end $$;
grant execute on function public.create_season_award(text) to authenticated;

-- قفل التصويتات اللي عدّى ميعادها + إعلان الفايز
create or replace function public.fn_close_polls()
returns void language plpgsql security definer set search_path = public as $$
declare r record; w text;
begin
  for r in select id, kind, question from public.polls
           where active and closes_at is not null and closes_at <= now() loop
    update public.polls set active = false where id = r.id;
    select label into w from public.poll_options where id = public.fn_poll_winner(r.id);
    insert into public.notifications (title, body, kind)
    values (case when r.kind = 'totw_tie' then '⚖️ اتحسم التعادل' else '🏆 ' || r.question end,
            coalesce('الفايز: ' || w, 'التصويت خلص'), 'vote');
  end loop;
end $$;

-- تعادل على آخر مكان في تشكيلة الجولة (أعلى ٥) → تصويت لحد نص الليل
create or replace function public.fn_totw_tie(p_cutoff timestamptz)
returns void language plpgsql security definer set search_path = public as $$
declare ids uuid[]; names text[]; ps bigint[]; above int; slots int; pid uuid;
begin
  if exists (select 1 from public.polls where kind = 'totw_tie' and window_end = p_cutoff) then return; end if;
  select array_agg(t.id order by t.points desc, t.name), array_agg(t.name order by t.points desc, t.name),
         array_agg(t.points order by t.points desc, t.name)
  into ids, names, ps
  from public.player_points_between(p_cutoff - interval '7 days', p_cutoff) t where t.points > 0;
  if ids is null or array_length(ids, 1) < 6 or ps[5] <> ps[6] then return; end if;
  select count(*) into above from unnest(ps) x where x > ps[5];
  slots := 5 - above;
  insert into public.polls (kind, question, active, window_end, closes_at, slots)
  values ('totw_tie', 'تعادل في تشكيلة الجولة — مين يدخل؟', true, p_cutoff,
          p_cutoff + interval '20 hours', slots)
  returning id into pid;
  insert into public.poll_options (poll_id, label, player_id)
  select pid, names[i], ids[i] from generate_subscripts(ids, 1) i where ps[i] = ps[5];
  insert into public.notifications (title, body, kind)
  values ('⚖️ تعادل في تشكيلة الجولة', 'لاعيبة جابوا نفس النقط على آخر ' ||
          case when slots = 1 then 'مكان' else slots || ' أماكن' end || ' — صوّت لحد نص الليل', 'vote');
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 18) BADGES — الشارات والإنجازات                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.user_badges (
  user_id   uuid references public.profiles(id) on delete cascade,
  badge     text not null,
  tier      int not null default 0,       -- 0 = لسه · 1 برونز · 2 فضة · 3 دهب
  value     int not null default 0,       -- التقدّم
  earned_at timestamptz,
  primary key (user_id, badge)
);
alter table public.user_badges enable row level security;
drop policy if exists "badges read" on public.user_badges;
create policy "badges read" on public.user_badges for select to authenticated using (true);

-- حدود المستويات (نفس BadgeCatalog في Dart)
create or replace function public.fn_badge_tier(b text, v int)
returns int language sql immutable as $$
  select case
    when b = 'first_100' then case when v between 1 and 100 then 3 when v between 1 and 500 then 2
                                   when v between 1 and 1000 then 1 else 0 end
    else (select count(*)::int from unnest(case b
      when 'streak' then array[5,10,25] when 'addict' then array[10,25,50]
      when 'early_bird' then array[1,10,30] when 'last_second' then array[1,5,15]
      when 'hawk_eye' then array[1,3,10] when 'right_captain' then array[1,5,15]
      when 'differential' then array[1,5,15] when 'golden_five' then array[1,5,15]
      when 'bench_betrayal' then array[1,5,15] when 'saviour' then array[1,3,10]
      when 'round_king' then array[1,3,10] when 'day_king' then array[1,5,15]
      when 'top10' then array[1,5,15] when 'rocket' then array[1,3,10]
      when 'record' then array[1,3,5] when 'league_leader' then array[1,5,15]
      when 'oracle' then array[1,3,10] when 'people_voice' then array[1,5,15]
      when 'critic' then array[5,20,50] when 'influencer' then array[5,15,50]
      when 'real_captain' then array[10,25,50] when 'beloved' then array[1,3,10]
      when 'people_captain' then array[1,3,10] when 'letdown' then array[1,2,3]
      else array[1,5,15] end) t where v >= t) end;
$$;

create or replace function public.fn_badge_name(b text)
returns text language sql immutable as $$
  select case b
    when 'streak' then 'مش بيفوّت' when 'addict' then 'المدمن' when 'first_100' then 'من الأوائل'
    when 'early_bird' then 'صاحي بدري' when 'last_second' then 'آخر ثانية'
    when 'hawk_eye' then 'عين الصقر' when 'right_captain' then 'الكابتن الصح'
    when 'differential' then 'ضد التيار' when 'golden_five' then 'الخماسي الذهبي'
    when 'bench_betrayal' then 'الاحتياطي خاني' when 'saviour' then 'المنقذ'
    when 'round_king' then 'ملك الجولة' when 'day_king' then 'ملك اليوم' when 'top10' then 'التوب ١٠'
    when 'rocket' then 'الصاروخ' when 'record' then 'رقم قياسي' when 'league_leader' then 'البطل'
    when 'oracle' then 'العرّاف' when 'people_voice' then 'صوت الشعب' when 'critic' then 'ناقد رياضي'
    when 'influencer' then 'المؤثر' when 'real_captain' then 'الكابتن الحقيقي'
    when 'beloved' then 'المحبوب' when 'people_captain' then 'كابتن الشعب' when 'letdown' then 'خيّب الظن'
    else b end;
$$;

create or replace function public.fn_set_badge(u uuid, b text, v int)
returns void language plpgsql security definer set search_path = public as $$
declare t int := public.fn_badge_tier(b, coalesce(v, 0)); old int;
begin
  v := coalesce(v, 0);
  select tier into old from public.user_badges where user_id = u and badge = b;
  if old is null then
    if v = 0 then return; end if;
    insert into public.user_badges (user_id, badge, tier, value, earned_at)
    values (u, b, t, v, case when t > 0 then now() end);
  else
    update public.user_badges set value = v, tier = greatest(tier, t),
      earned_at = case when t > tier then now() else earned_at end
    where user_id = u and badge = b;
  end if;
  if t > coalesce(old, 0) then
    insert into public.notifications (title, body, kind, user_id)
    values ('🏅 شارة جديدة: ' || public.fn_badge_name(b),
            case t when 1 then 'برونز 🥉' when 2 then 'فضة 🥈' else 'دهب 🥇' end || ' — افتح إنجازاتك وشيّرها',
            'badge', u);
  end if;
end $$;

create or replace function public.fn_bump_badge(u uuid, b text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_set_badge(u, b,
    coalesce((select value from public.user_badges where user_id = u and badge = b), 0) + 1);
end $$;

-- حقائق كل لاعب في تشكيلات اليوزر في الماتشات اللي خلصت
create or replace function public.fn_user_pick_facts(u uuid)
returns table(match_id uuid, player_id uuid, status text, is_captain boolean, is_vice boolean,
              saved_at timestamptz, date_time timestamptz, base int, played boolean, goals int,
              match_max int, owner_pct numeric, chip text)
language sql stable security definer set search_path = public as $$
  with mine as (
    select p.match_id, p.player_id, p.status, p.is_captain, p.is_vice, p.saved_at, m.date_time
    from public.picks p join public.matches m on m.id = p.match_id
    where p.user_id = u and m.status = 'finished'
  ), ev as (
    select e.match_id, e.player_id, sum(public.fn_event_points(e.type, pl.position))::int as pts,
           (count(*) filter (where e.type = 'goal'))::int as goals
    from public.events e join public.players pl on pl.id = e.player_id
    where e.match_id in (select mine.match_id from mine)
    group by e.match_id, e.player_id
  ), mx as (
    select ev.match_id, max(ev.pts) as mx from ev group by ev.match_id
  ), own as (
    select p.match_id, p.player_id, count(distinct p.user_id)::numeric as n from public.picks p
    where p.match_id in (select mine.match_id from mine) group by p.match_id, p.player_id
  ), tot as (
    select p.match_id, count(distinct p.user_id)::numeric as n from public.picks p
    where p.match_id in (select mine.match_id from mine) group by p.match_id
  )
  select mine.match_id, mine.player_id, mine.status, mine.is_captain, mine.is_vice, mine.saved_at,
    mine.date_time, coalesce(ev.pts, 0), ev.player_id is not null, coalesce(ev.goals, 0),
    coalesce(mx.mx, 0), round(coalesce(own.n, 0) * 100 / greatest(tot.n, 1), 1),
    (select c.chip from public.chip_uses c where c.user_id = u and c.match_id = mine.match_id)
  from mine
  left join ev on ev.match_id = mine.match_id and ev.player_id = mine.player_id
  left join mx on mx.match_id = mine.match_id
  left join own on own.match_id = mine.match_id and own.player_id = mine.player_id
  left join tot on tot.match_id = mine.match_id;
$$;

-- الشارات الشخصية لليوزر (بتتحسب لما يبقى عنده نشاط جديد)
create or replace function public.fn_award_badges(u uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v int;
begin
  drop table if exists _pf;
  create temp table _pf as select * from public.fn_user_pick_facts(u);

  perform public.fn_set_badge(u, 'hawk_eye',
    (select count(distinct match_id) from _pf where is_captain and goals >= 3)::int);
  perform public.fn_set_badge(u, 'right_captain',
    (select count(distinct match_id) from _pf where is_captain and base > 0 and base >= match_max)::int);
  perform public.fn_set_badge(u, 'differential',
    (select count(distinct match_id) from _pf where status = 'starting' and base >= 10 and owner_pct < 10)::int);
  perform public.fn_set_badge(u, 'golden_five', (select count(*) from (
    select match_id from _pf where status = 'starting' group by match_id
    having count(*) filter (where base > 0) = 5) x)::int);
  perform public.fn_set_badge(u, 'bench_betrayal', (select count(*) from (
    select match_id from _pf group by match_id
    having coalesce(max(chip), '') <> 'bench_boost'
       and coalesce(sum(base) filter (where status = 'bench'), 0) > coalesce(sum(base) filter (where status = 'starting'), 0)) x)::int);
  perform public.fn_set_badge(u, 'saviour', (select count(*) from (
    select match_id from _pf group by match_id
    having not bool_or(is_captain and played)
       and coalesce(max(base) filter (where is_vice), 0) >= 8) x)::int);
  perform public.fn_set_badge(u, 'early_bird', (select count(*) from (
    select match_id from _pf group by match_id
    having max(saved_at) <= max(date_time) - interval '24 hours') x)::int);
  perform public.fn_set_badge(u, 'last_second', (select count(*) from (
    select match_id from _pf group by match_id
    having max(saved_at) > max(date_time) - interval '61 minutes'
       and max(saved_at) <= max(date_time) - interval '1 hour') x)::int);
  drop table if exists _pf;

  -- مش بيفوّت: أطول سلسلة جولات ورا بعض فيها تشكيلة
  select coalesce(max(n), 0) into v from (
    select count(*) as n from (
      select wk - (row_number() over (order by wk)) * interval '7 days' as grp
      from (select distinct public.fn_week_cutoff(m.date_time) as wk
            from public.picks p join public.matches m on m.id = p.match_id where p.user_id = u) w
    ) g group by grp) s;
  perform public.fn_set_badge(u, 'streak', v);

  -- المدمن: أطول سلسلة ماتشات ورا بعض (من الماتشات اللي نزلت تشكيلتها) من غير ما يفوّت
  select coalesce(max(n), 0) into v from (
    select count(*) as n from (
      select rn - row_number() over (order by rn) as grp from (
        select m.id, row_number() over (order by m.date_time) as rn from public.matches m
        where m.date_time <= now() and exists (select 1 from public.lineups l where l.match_id = m.id)
      ) am where exists (select 1 from public.picks p where p.user_id = u and p.match_id = am.id)
    ) g group by grp) s;
  perform public.fn_set_badge(u, 'addict', v);

  perform public.fn_set_badge(u, 'oracle', (select count(*) from public.predictions pr
    join public.matches m on m.id = pr.match_id
    where pr.user_id = u and m.is_challenge and m.status = 'finished'
      and pr.score_a = m.score_a and pr.score_b = m.score_b)::int);
  perform public.fn_set_badge(u, 'critic',
    (select count(distinct match_id) from public.player_ratings where user_id = u)::int);
  perform public.fn_set_badge(u, 'people_voice', (select count(*) from public.poll_votes pv
    join public.polls p on p.id = pv.poll_id
    where pv.user_id = u and not p.active and pv.option_id = public.fn_poll_winner(p.id))::int);
  perform public.fn_set_badge(u, 'influencer',
    (select count(*) from public.profiles where referred_by = u)::int);
  perform public.fn_set_badge(u, 'real_captain', (select coalesce(max(c), 0) from (
    select count(*) as c from public.leagues l join public.league_members lm on lm.league_id = l.id
    where l.owner_id = u group by l.id) x)::int);
  perform public.fn_set_badge(u, 'first_100', (select count(*) from public.profiles
    where created_at <= (select created_at from public.profiles where id = u))::int);
  -- رقم قياسي: كام مرة نقطك في ماتش كسرت أعلى رقم في تاريخ التطبيق وقتها
  perform public.fn_set_badge(u, 'record', (select count(*) from public.user_match_points a
    join public.matches ma on ma.id = a.match_id
    where a.user_id = u and ma.status = 'finished' and a.points > 0
      and a.points > coalesce((select max(b.points) from public.user_match_points b
        join public.matches mb on mb.id = b.match_id
        where mb.status = 'finished' and mb.date_time < ma.date_time), 0))::int);
end $$;

-- شارات الجولة (بتتحسب مرة واحدة لما الجولة تقفل الجمعة ٤ الفجر)
create or replace function public.fn_round_badges(p_cutoff timestamptz)
returns void language plpgsql security definer set search_path = public as $$
declare f timestamptz := p_cutoff - interval '7 days'; r record; best int;
begin
  drop table if exists _rt;
  create temp table _rt as
    select ump.user_id, sum(ump.points)::int as pts
    from public.user_match_points ump join public.matches m on m.id = ump.match_id
    where m.date_time > f and m.date_time <= p_cutoff group by ump.user_id;

  select max(pts) into best from _rt;
  if best > 0 then
    for r in select user_id from _rt where pts = best loop
      perform public.fn_bump_badge(r.user_id, 'round_king');
    end loop;
  end if;
  for r in select user_id from (select user_id, rank() over (order by pts desc) as rk from _rt where pts > 0) x
           where rk <= 10 loop
    perform public.fn_bump_badge(r.user_id, 'top10');
  end loop;

  -- الصاروخ: طلع ٢٠ مركز أو أكتر في الترتيب العام في الجولة دي
  for r in
    with b as (select ump.user_id, sum(ump.points) as s from public.user_match_points ump
               join public.matches m on m.id = ump.match_id where m.date_time <= f group by ump.user_id),
         a as (select ump.user_id, sum(ump.points) as s from public.user_match_points ump
               join public.matches m on m.id = ump.match_id where m.date_time <= p_cutoff group by ump.user_id),
         rb as (select user_id, rank() over (order by s desc) as rk from b),
         ra as (select user_id, rank() over (order by s desc) as rk from a)
    select ra.user_id from ra join rb on rb.user_id = ra.user_id where rb.rk - ra.rk >= 20 loop
    perform public.fn_bump_badge(r.user_id, 'rocket');
  end loop;

  -- ملك اليوم: الأعلى في كل يوم من أيام الجولة
  for r in
    with d as (select ump.user_id, (m.date_time at time zone 'Africa/Cairo')::date as dy, sum(ump.points) as s
               from public.user_match_points ump join public.matches m on m.id = ump.match_id
               where m.date_time > f and m.date_time <= p_cutoff group by 1, 2),
         mx as (select dy, max(s) as mx from d group by dy)
    select d.user_id from d join mx on mx.dy = d.dy where d.s = mx.mx and mx.mx > 0 loop
    perform public.fn_bump_badge(r.user_id, 'day_king');
  end loop;

  -- البطل: الأول في دوري (٣ أعضاء أو أكتر) لما الجولة قفلت
  for r in select distinct on (lm.league_id) lm.user_id from public.league_members lm
           join public.profiles p on p.id = lm.user_id
           where p.total_points > 0
             and (select count(*) from public.league_members x where x.league_id = lm.league_id) >= 3
           order by lm.league_id, p.total_points desc loop
    perform public.fn_bump_badge(r.user_id, 'league_leader');
  end loop;

  -- شارات اللاعيبة الموثّقين
  for r in select pl.user_id from public.player_window_stats(f, p_cutoff) s
           join public.players pl on pl.id = s.id where pl.user_id is not null and s.ownership > 50 loop
    perform public.fn_bump_badge(r.user_id, 'beloved');
  end loop;
  for r in
    with c as (select p.player_id, count(*) as n from public.picks p join public.matches m on m.id = p.match_id
               where p.is_captain and m.date_time > f and m.date_time <= p_cutoff group by p.player_id)
    select pl.user_id from c join public.players pl on pl.id = c.player_id
    where pl.user_id is not null and c.n = (select max(n) from c) loop
    perform public.fn_bump_badge(r.user_id, 'people_captain');
  end loop;
  for r in
    select pl.user_id from (
      select p.match_id, p.player_id from public.picks p join public.matches m on m.id = p.match_id
      where p.is_captain and m.status = 'finished' and m.date_time > f and m.date_time <= p_cutoff
      group by p.match_id, p.player_id having count(*) >= 30) c
    join public.players pl on pl.id = c.player_id
    where pl.user_id is not null
      and coalesce((select sum(public.fn_event_points(e.type, pl.position)) from public.events e
                    where e.match_id = c.match_id and e.player_id = c.player_id), 0) <= 0 loop
    perform public.fn_bump_badge(r.user_id, 'letdown');
  end loop;

  update public.profiles set badges_dirty = true where id in (select user_id from _rt);
  drop table if exists _rt;
end $$;

-- الشارات الشخصية لليوزرز اللي عندهم نشاط جديد (دفعة محدودة كل مرة)
create or replace function public.fn_award_dirty_badges(p_limit int)
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select id from public.profiles where badges_dirty limit p_limit loop
    perform public.fn_award_badges(r.id);
    update public.profiles set badges_dirty = false where id = r.id;
  end loop;
end $$;

-- أي نشاط جديد (توقّع/تقييم/تصويت) → شاراته تتحسب في الدورة الجاية
create or replace function public.trg_mark_badges_dirty()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.profiles set badges_dirty = true where id = new.user_id and not badges_dirty;
  return null;
end $$;
drop trigger if exists predictions_dirty on public.predictions;
create trigger predictions_dirty after insert on public.predictions
for each row execute function public.trg_mark_badges_dirty();
drop trigger if exists ratings_dirty on public.player_ratings;
create trigger ratings_dirty after insert on public.player_ratings
for each row execute function public.trg_mark_badges_dirty();
drop trigger if exists votes_dirty on public.poll_votes;
create trigger votes_dirty after insert on public.poll_votes
for each row execute function public.trg_mark_badges_dirty();


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 19) TICK — مهمة كل ١٠ دقايق                                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.app_jobs (
  key     text primary key,
  done_at timestamptz not null default now()
);
alter table public.app_jobs enable row level security;   -- مفيش سياسات = محدش يوصله من التطبيق

-- اللاعيبة الموثّقين: "انت كابتن عند N واحد" أول ما التشكيلات تقفل
create or replace function public.fn_notify_captains()
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select id, teams from public.matches
           where not captains_notified and status = 'upcoming'
             and date_time - interval '1 hour' <= now() and date_time > now() - interval '6 hours' loop
    update public.matches set captains_notified = true where id = r.id;
    insert into public.notifications (title, body, kind, user_id, match_id)
    select '🔥 انت كابتن عند ' || count(*) || ' واحد', r.teams[1] || ' ضد ' || r.teams[2] || ' — ورّيهم',
           'status', pl.user_id, r.id
    from public.picks p join public.players pl on pl.id = p.player_id
    where p.match_id = r.id and p.is_captain and pl.user_id is not null
    group by pl.user_id;
  end loop;
end $$;

-- p_limit: كام يوزر تتحسب شاراتهم في الدورة (pg_cron: 300 · التطبيق: 20)
create or replace function public.fn_tick(p_limit int default 20)
returns void language plpgsql security definer set search_path = public as $$
declare last timestamptz; c timestamptz; cp timestamptz; k text;
begin
  if not pg_try_advisory_xact_lock(424242) then return; end if;
  select done_at into last from public.app_jobs where key = 'tick';
  if last is not null and last > now() - interval '4 minutes' then return; end if;
  insert into public.app_jobs (key, done_at) values ('tick', now())
  on conflict (key) do update set done_at = excluded.done_at;

  perform public.fn_close_ratings();
  perform public.fn_notify_captains();
  perform public.fn_close_polls();
  perform public.fn_update_tiebreak();

  c := public.fn_week_cutoff(now());
  cp := c - interval '7 days';                         -- آخر جولة قفلت
  k := 'round:' || to_char(cp at time zone 'UTC', 'YYYYMMDDHH24');
  if now() > cp then
    insert into public.app_jobs (key) values (k) on conflict do nothing;
    if found then
      if now() < cp + interval '20 hours' then
        perform public.fn_totw_tie(cp);                -- التعادل بيتعمل بس وقت عرض النهائي
      end if;
      perform public.fn_round_badges(cp);
    end if;
  end if;

  perform public.fn_award_dirty_badges(least(greatest(p_limit, 1), 300));
end $$;
grant execute on function public.fn_tick(int) to authenticated;

-- جدولة كل ١٠ دقايق (لو pg_cron مش متفعّل، التطبيق بينادي fn_tick كاحتياطي)
do $$ begin
  create extension if not exists pg_cron;
  perform cron.schedule('khomasi-tick', '*/10 * * * *', 'select public.fn_tick(300)');
exception when others then
  raise notice 'pg_cron مش متاح: فعّله من Database → Extensions وشغّل الملف تاني';
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 20) PUSH — أي إشعار بيتسجّل → push أوتوماتيك                   ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- الـ trigger بيبعت id الإشعار لـ Edge Function اسمها push (pg_net)، وهي بتبعت FCM:
--   all → topic "all" · user → توكن اليوزر · match → توكنات متابعين الماتش.
-- النشر: npx supabase functions deploy push --no-verify-jwt --project-ref jhofyglkpwguzodbeyia

do $$ begin
  create extension if not exists pg_net;
exception when others then
  raise notice 'pg_net مش متاح: فعّله من Database → Extensions وشغّل الملف تاني';
end $$;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table if not exists private.settings (key text primary key, value text not null);
insert into private.settings (key, value)
values ('push_url', 'https://jhofyglkpwguzodbeyia.supabase.co/functions/v1/push')
on conflict (key) do nothing;
insert into private.settings (key, value)
values ('push_secret', replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''))
on conflict (key) do nothing;

-- الـ Edge Function بتتأكد إن الطلب جاي من الداتابيز (service_role بس يقدر يناديها)
create or replace function public.push_secret_ok(s text)
returns boolean language sql stable security definer set search_path = public, private as $$
  select exists (select 1 from private.settings where key = 'push_secret' and value = s);
$$;
revoke execute on function public.push_secret_ok(text) from public, anon, authenticated;
grant execute on function public.push_secret_ok(text) to service_role;

create or replace function public.trg_notification_push()
returns trigger language plpgsql security definer set search_path = public, private as $$
declare u text; s text;
begin
  select value into u from private.settings where key = 'push_url';
  select value into s from private.settings where key = 'push_secret';
  if u is not null then
    perform net.http_post(url := u, body := jsonb_build_object('id', new.id, 'secret', s),
                          headers := jsonb_build_object('Content-Type', 'application/json'));
  end if;
  return new;
exception when others then
  return new;   -- الـ push عمره ما يوقّف تسجيل الإشعار
end $$;
drop trigger if exists notification_push on public.notifications;
create trigger notification_push after insert on public.notifications
for each row execute function public.trg_notification_push();

-- Realtime للجداول اللي اليوزر بيشوفها (أي تعديل من المدير يظهر فورًا)
do $$
declare t text;
begin
  foreach t in array array['lineups', 'players', 'events', 'polls', 'venues', 'picks', 'matches',
                           'bookings', 'user_badges', 'venue_reviews'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;


-- ═══════════════════════════════════════════════════════════════
-- خلصنا. (اختياري) خلّي نفسك مدير — بدّل الإيميل بإيميلك:
--   update public.profiles set role = 'manager' where email = 'you@email.com';
-- ═══════════════════════════════════════════════════════════════
