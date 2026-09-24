-- ═══════════════════════════════════════════════════════════════
-- الخماسي — كل الـ migrations في ملف واحد (شغّله مرة واحدة)
-- Supabase Dashboard → SQL Editor → New query → الصق الكل → Run
--
-- الترتيب مهم ومظبوط هنا:
--   1) schema            — الجداول + RLS (من غير بيانات تجريبية)
--   2) manager & scoring — دور المدير + محرك النقاط + إحصائيات اللاعب
--   3) lineups           — تشكيلة كل ماتش (المدير)
--   4) picks             — اختيار اليوزر لكل ماتش + الكابتن/الاحتياطي + إعادة حساب النقاط
--   5) team of week      — نقاط الجولة + الامتلاك + الدخول/الخروج + تاريخ اللاعب
--   6) notifications     — صندوق الإشعارات (للكل أو ليوزر محدّد)
--   7) polls             — نجم الجولة + تحدّي الجولة
--   8) admin             — نتيجة الماتش + أدوار المستخدمين + حذف الدوريات
--   9) venues & bookings — الملاعب على الخريطة + الصور + الحجز بموافقة صاحب الملعب
--  10) fcm               — عمود توكن الإشعارات
--
-- كله idempotent — تقدر تعيد تشغيله من غير ما يكسّر حاجة.
-- ملاحظة: picks بيعيد تعريف fn_recalc_users عشان يحسب per-match، فلازم يجي بعد manager_and_scoring.
-- ═══════════════════════════════════════════════════════════════


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 1) SCHEMA                                                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- ── profiles: بيانات المستخدم (مرتبطة بـ auth.users) ──
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null default '',
  email       text not null default '',
  phone       text,
  role        text not null default 'user',        -- 'user' | 'manager'
  team        text[] not null default '{}',         -- ids اللاعيبة في التشكيلة
  league_id   uuid,
  photo_url   text,
  position    text,
  captain_id  uuid,                                 -- كابتن التشكيلة
  total_points int not null default 0,              -- نقاط اللاعب الإجمالية (للترتيب)
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

-- ── players: اللاعيبة ──
create table if not exists public.players (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  team          text not null default '',
  position      text not null default '',           -- GK | DEF | MID | FWD
  price         numeric not null default 0,
  image_url     text,
  total_points  int not null default 0,              -- إجمالي النقاط
  form          numeric not null default 0,          -- الفورمة (0..10)
  goals         int not null default 0,
  assists       int not null default 0,
  clean_sheets  int not null default 0,
  yellow_cards  int not null default 0,
  availability  text not null default 'ready',       -- ready | injured | doubtful | suspended
  news          text                                 -- سبب/تفاصيل حالة اللاعب (المدير بيكتبها)
);
alter table public.players add column if not exists availability text not null default 'ready';
alter table public.players add column if not exists news text;

-- ── matches: الماتشات/الجولات ──
create table if not exists public.matches (
  id         uuid primary key default gen_random_uuid(),
  date_time  timestamptz not null,
  teams      text[] not null default '{}',
  status     text not null default 'upcoming',      -- upcoming | finished
  week       int not null default 0,
  fdr        int not null default 3                 -- صعوبة الماتش 1..5
);

-- ── leagues: الدوريات ──
create table if not exists public.leagues (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  type         text not null default 'public',      -- public | private | h2h
  invite_code  text unique
);

-- ── league_members: عضوية الدوريات (join table) ──
create table if not exists public.league_members (
  league_id  uuid references public.leagues(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  joined_at  timestamptz not null default now(),
  primary key (league_id, user_id)
);

-- ── venues: ملاعب الحجز ──
create table if not exists public.venues (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  price        int not null default 0,               -- جنيه/ساعة
  distance_km  numeric not null default 0,
  surface      text not null default 'نجيلة صناعية',
  feature      text,                                  -- إضاءة / مغطّى ...
  capacity     int not null default 10,
  filled       int not null default 0,
  slot_time    text default ''
);

-- ── auctions: غرف المزاد المباشر ──
create table if not exists public.auctions (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,
  current_player_id uuid references public.players(id) on delete set null,
  base_price        numeric not null default 6,
  ends_at           timestamptz,
  status            text not null default 'live'     -- live | ended
);

create table if not exists public.auction_bids (
  id          uuid primary key default gen_random_uuid(),
  auction_id  uuid references public.auctions(id) on delete cascade,
  user_id     uuid references public.profiles(id) on delete cascade,
  bidder_name text not null default '',
  amount      numeric not null,
  created_at  timestamptz not null default now()
);

-- ── events: أحداث الماتشات (النقاط) ──
create table if not exists public.events (
  id         uuid primary key default gen_random_uuid(),
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  type       text not null,                          -- goal | assist | cleanSheet | save | yellowCard ...
  minute     int                                     -- دقيقة الحدث (النقاط بتتحسب بالمحرك)
);

-- دالة آمنة: تحويل رقم الموبايل → إيميل (للدخول بالرقم قبل المصادقة)
create or replace function public.email_for_phone(p text)
returns text
language sql
security definer
set search_path = public
as $$
  select email from public.profiles where phone = p limit 1;
$$;
grant execute on function public.email_for_phone(text) to anon, authenticated;

-- ── Row Level Security ──
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
create policy "auctions read" on public.auctions for select to authenticated using (true);
create policy "bids read"     on public.auction_bids for select to authenticated using (true);
create policy "bids insert"   on public.auction_bids for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "leagues read"   on public.leagues;
drop policy if exists "leagues insert" on public.leagues;
create policy "leagues read"   on public.leagues for select to authenticated using (true);
create policy "leagues insert" on public.leagues for insert to authenticated with check (true);

drop policy if exists "members read"   on public.league_members;
drop policy if exists "members insert" on public.league_members;
drop policy if exists "members delete" on public.league_members;
create policy "members read"   on public.league_members for select to authenticated using (true);
create policy "members insert" on public.league_members for insert to authenticated with check (auth.uid() = user_id);
create policy "members delete" on public.league_members for delete to authenticated using (auth.uid() = user_id);

-- ── مفيش بيانات تجريبية ──
-- كل المحتوى (لاعيبة/ماتشات/دوريات/ملاعب) بيضيفه المدير من داخل التطبيق.

-- إصلاح ربط المزاد باللاعب: خلّيه on delete set null (للقواعد القديمة كمان)
-- عشان حذف لاعب معروض في مزاد ما يفشلش بـ foreign key.
alter table public.auctions drop constraint if exists auctions_current_player_id_fkey;
alter table public.auctions add constraint auctions_current_player_id_fkey
  foreign key (current_player_id) references public.players(id) on delete set null;

-- تفعيل الـ Realtime (idempotent) — للمزاد + الماتشات + الإشعارات (تحديث فوري في الهوم)
do $$ begin
  alter publication supabase_realtime add table public.auction_bids;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.auctions;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.matches;
exception when duplicate_object then null; end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 2) MANAGER & SCORING                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- ── هل المستخدم الحالي مدير؟ ──
create or replace function public.is_manager()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'manager');
$$;

-- ═══ صلاحيات المدير: يكتب في المحتوى (لاعيبة/ماتشات/أحداث/ملاعب) ═══
drop policy if exists "players manager write" on public.players;
create policy "players manager write" on public.players for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

drop policy if exists "matches manager write" on public.matches;
create policy "matches manager write" on public.matches for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

drop policy if exists "events manager write" on public.events;
create policy "events manager write" on public.events for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

drop policy if exists "venues manager write" on public.venues;
create policy "venues manager write" on public.venues for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

-- ═══ نقاط الحدث حسب النوع والمركز (يطابق PointsEngine في Dart) ═══
create or replace function public.fn_event_points(p_type text, p_pos text)
returns int language sql immutable as $$
  select case
    when p_type = 'appearance'  then 1
    when p_type = 'goal'        then case when p_pos in ('GK','DEF') then 6 when p_pos='MID' then 5 else 4 end
    when p_type = 'assist'      then 3
    when p_type = 'cleanSheet'  then case when p_pos in ('GK','DEF') then 4 when p_pos='MID' then 1 else 0 end
    when p_type = 'save'        then 1
    when p_type = 'penaltySave' then 5
    when p_type = 'motm'        then 3
    when p_type = 'bonus'       then 3
    when p_type = 'yellowCard'  then -1
    when p_type = 'redCard'     then -3
    when p_type = 'ownGoal'     then -2
    when p_type = 'penaltyMiss' then -2
    else 0
  end;
$$;

-- ── إعادة حساب إحصائيات لاعب من أحداثه (نقاط + أهداف + أسيست + شباك + كروت + فورمة) ──
-- الفورمة = متوسط نقاطه في آخر ٣ جولات لعبها.
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

-- ملاحظة: fn_recalc_users بيتعرّف نهائيًا في قسم PICKS تحت (per-match).


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 3) LINEUPS                                                     ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.lineups (
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  status     text not null default 'bench',   -- starting | bench  (مش موجود = بره التشكيلة)
  primary key (match_id, player_id)
);

alter table public.lineups enable row level security;

drop policy if exists "lineups read" on public.lineups;
create policy "lineups read" on public.lineups
  for select to authenticated using (true);

drop policy if exists "lineups manager write" on public.lineups;
create policy "lineups manager write" on public.lineups
  for all to authenticated
  using (public.is_manager()) with check (public.is_manager());


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 4) PICKS (النموذج الجديد: تشكيلة لكل ماتش)                     ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.picks (
  user_id    uuid references public.profiles(id) on delete cascade,
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  status     text not null default 'starting',   -- starting | bench
  is_captain boolean not null default false,
  is_vice    boolean not null default false,     -- كابتن احتياطي (يشتغل لو الكابتن ملعبش)
  primary key (user_id, match_id, player_id)
);
alter table public.picks add column if not exists is_vice boolean not null default false;

alter table public.picks enable row level security;
drop policy if exists "picks read" on public.picks;
drop policy if exists "picks own write" on public.picks;
create policy "picks read" on public.picks for select to authenticated using (true);
create policy "picks own write" on public.picks for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══ نقاط يوزر واحد من اختياراته في الماتشات ═══
-- الأساسيين فقط. الكابتن ×2 لو لعب؛ لو الكابتن ملعبش → الكابتن الاحتياطي ×2.
create or replace function public.fn_user_points(p_user uuid)
returns int language sql stable security definer set search_path = public as $$
  select coalesce(sum(
      (select coalesce(sum(public.fn_event_points(e.type, pl.position)), 0)
       from public.events e
       where e.player_id = pk.player_id and e.match_id = pk.match_id)
      * case
          when pk.is_captain and exists(
            select 1 from public.events ce
            where ce.player_id = pk.player_id and ce.match_id = pk.match_id
          ) then 2
          when pk.is_vice and not exists(
            select 1 from public.picks cap
            join public.events ce on ce.player_id = cap.player_id and ce.match_id = cap.match_id
            where cap.user_id = pk.user_id and cap.match_id = pk.match_id and cap.is_captain
          ) then 2
          else 1
        end
    ), 0)::int
  from public.picks pk
  join public.players pl on pl.id = pk.player_id
  where pk.user_id = p_user and pk.status = 'starting';
$$;

-- إعادة حساب نقاط كل المستخدمين (للاستخدام اليدوي من SQL Editor).
-- ⚠️ كل UPDATE لازم يبقى ليه WHERE: Supabase مشغّل pg-safeupdate على طلبات التطبيق
-- وبيرفض أي UPDATE من غير WHERE — ودي كانت سبب إن التشكيلة والأحداث مبتتحفظش.
create or replace function public.fn_recalc_users()
returns void language sql security definer set search_path = public as $$
  update public.profiles set total_points = public.fn_user_points(id) where id is not null;
$$;

-- تريجر: أي تغيير في events → أعد حساب اللاعب + اليوزرز اللي ليهم تشكيلة في الماتش ده بس
create or replace function public.trg_events_recalc()
returns trigger language plpgsql security definer set search_path = public as $$
declare m uuid := coalesce(new.match_id, old.match_id);
begin
  perform public.fn_recalc_player(coalesce(new.player_id, old.player_id));
  update public.profiles set total_points = public.fn_user_points(id)
  where id in (select distinct user_id from public.picks where match_id = m);
  return null;
end;
$$;
drop trigger if exists events_recalc on public.events;
create trigger events_recalc
after insert or update or delete on public.events
for each row execute function public.trg_events_recalc();

-- تريجر: أي تغيير في picks → أعد حساب نقاط صاحب التشكيلة ده بس
create or replace function public.trg_picks_recalc()
returns trigger language plpgsql security definer set search_path = public as $$
declare u uuid := coalesce(new.user_id, old.user_id);
begin
  update public.profiles set total_points = public.fn_user_points(u) where id = u;
  return null;
end; $$;
drop trigger if exists picks_recalc on public.picks;
create trigger picks_recalc
after insert or update or delete on public.picks
for each row execute function public.trg_picks_recalc();

-- نظبّط نقاط الكل مرة واحدة بالحساب الجديد
select public.fn_recalc_users();

-- التريجر القديم اللي كان بيحسب من profiles.team مبقاش ليه لازمة
drop trigger if exists profile_recalc on public.profiles;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 5) TEAM OF THE WEEK                                            ║
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

-- ═══ إحصائيات كل لاعب في جولة: النقاط + الامتلاك + الدخول/الخروج ═══
-- الامتلاك = % من اليوزرز اللي اختاروه في الجولة (من كل اللي عملوا تشكيلة فيها).
-- الدخول = اختاروه الجولة دي ومكانوش مختارينه اللي قبلها. الخروج = العكس.
create or replace function public.player_gw_stats(w int)
returns table(id uuid, points bigint, owners bigint, ownership numeric,
              transfers_in bigint, transfers_out bigint)
language sql stable as $$
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

-- ═══ نقاط لاعب في كل جولة (للرسم في صفحة اللاعب) ═══
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

-- ═══ الجولة بالوقت (مش برقم الجولة) ═══
-- الجولة = من جمعة 4 الفجر لجمعة 4 الفجر اللي بعدها (التطبيق بيحسب الحدود ويبعتها).
-- أي ماتش بيتحسب في الجولة اللي ميعاده جواها: p_from < date_time <= p_to.

-- نقاط كل لاعب في فترة (لنجوم الجولة / أعلى ٥ في اليوم / تشكيلة الأسبوع)
create or replace function public.player_points_between(p_from timestamptz, p_to timestamptz)
returns table(id uuid, name text, team text, "position" text, points bigint)
language sql stable as $$
  select pl.id, pl.name, pl.team, pl.position,
    sum(public.fn_event_points(e.type, pl.position))::bigint as points
  from public.events e
  join public.matches m on m.id = e.match_id and m.date_time > p_from and m.date_time <= p_to
  join public.players pl on pl.id = e.player_id
  group by pl.id, pl.name, pl.team, pl.position
  having sum(public.fn_event_points(e.type, pl.position)) <> 0
  order by points desc;
$$;
grant execute on function public.player_points_between(timestamptz, timestamptz) to authenticated;

-- إحصائيات كل لاعب في الجولة (بالوقت): النقاط + الامتلاك الحقيقي + الدخول/الخروج.
-- الامتلاك = عدد اليوزرز اللي اختاروه في ماتشات الجولة ÷ كل اليوزرز اللي عملوا تشكيلة في الجولة.
-- managers = عدد اليوزرز اللي عملوا تشكيلة (المقام) — عشان التطبيق يعرض "اختاره 5 من 12".
create or replace function public.player_window_stats(p_from timestamptz, p_to timestamptz)
returns table(id uuid, points bigint, owners bigint, ownership numeric,
              transfers_in bigint, transfers_out bigint, managers bigint)
language sql stable as $$
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
  )
  select pl.id,
    coalesce((select sum(public.fn_event_points(e.type, pl.position))
              from public.events e join public.matches m on m.id = e.match_id
              where e.player_id = pl.id and m.date_time > p_from and m.date_time <= p_to), 0)::bigint,
    (select count(*) from cur c where c.player_id = pl.id)::bigint,
    case when (select n from total) = 0 then 0
         else round((select count(*) from cur c where c.player_id = pl.id) * 100.0 / (select n from total), 1) end,
    (select count(*) from cur c where c.player_id = pl.id and not exists (
       select 1 from prev p where p.user_id = c.user_id and p.player_id = pl.id))::bigint,
    (select count(*) from prev p where p.player_id = pl.id and not exists (
       select 1 from cur c where c.user_id = p.user_id and c.player_id = pl.id))::bigint,
    (select n from total)::bigint
  from public.players pl;
$$;
grant execute on function public.player_window_stats(timestamptz, timestamptz) to authenticated;

-- إعادة حساب إحصائيات كل اللاعيبة الموجودين (مرة واحدة)
select public.fn_recalc_player(id) from public.players;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 6) NOTIFICATIONS (صندوق إشعارات داخل التطبيق)                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  body       text not null default '',
  kind       text not null default 'event',   -- lineup | match | event | status (لتمييز الصوت)
  match_id   uuid references public.matches(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.notifications add column if not exists kind text not null default 'event';
-- user_id فاضي = للكل. لو متحدّد = إشعار موجّه ليوزر واحد (زي التذكير).
alter table public.notifications add column if not exists user_id uuid references public.profiles(id) on delete cascade;

alter table public.notifications enable row level security;

drop policy if exists "notifications read" on public.notifications;
create policy "notifications read" on public.notifications
  for select to authenticated using (user_id is null or user_id = auth.uid());

drop policy if exists "notifications manager write" on public.notifications;
create policy "notifications manager write" on public.notifications
  for insert to authenticated with check (public.is_manager());

-- realtime للإشعارات (تظهر فورًا عند اليوزرز)
do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 7) POLLS (نجم الجولة + تحدّي الجولة — المدير يحط واليوزرز يصوّتوا) ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.polls (
  id         uuid primary key default gen_random_uuid(),
  kind       text not null,                 -- 'star' | 'challenge'
  question   text not null default '',
  active     boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.poll_options (
  id        uuid primary key default gen_random_uuid(),
  poll_id   uuid references public.polls(id) on delete cascade,
  label     text not null,
  player_id uuid references public.players(id) on delete set null
);

create table if not exists public.poll_votes (
  poll_id    uuid references public.polls(id) on delete cascade,
  option_id  uuid references public.poll_options(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (poll_id, user_id)            -- صوت واحد لكل يوزر في كل تصويت
);

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
-- اليوزر يصوّت بنفسه بس، وعلى تصويت لسه مفتوح بس.
create policy "poll_votes own write" on public.poll_votes for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id
    and exists (select 1 from public.polls p where p.id = poll_id and p.active));

-- realtime عشان النتائج تتحدّث فورًا
do $$ begin
  alter publication supabase_realtime add table public.poll_votes;
exception when duplicate_object then null; end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 8) ADMIN (نتيجة الماتش + أدوار المستخدمين + حذف الدوريات)       ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- نتيجة الماتش (المدير بيكتبها وهو بيقفل الماتش)
alter table public.matches add column if not exists score_a int;
alter table public.matches add column if not exists score_b int;

-- تغيير دور مستخدم (user ↔ manager) — المدير بس، من غير ما يفتح تعديل البروفايلات كلها.
create or replace function public.set_user_role(uid uuid, new_role text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'not allowed'; end if;
  if new_role not in ('user', 'manager') then raise exception 'bad role'; end if;
  update public.profiles set role = new_role where id = uid;
end; $$;
grant execute on function public.set_user_role(uuid, text) to authenticated;

-- المدير يقدر يحذف دوري
drop policy if exists "leagues manager delete" on public.leagues;
create policy "leagues manager delete" on public.leagues
  for delete to authenticated using (public.is_manager());


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 9) VENUES & BOOKINGS (الملاعب على الخريطة + الصور + الحجز)       ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- بيانات الملعب الجديدة: الموقع + التليفون + العنوان + مواعيد التشغيل + الصور + صاحبه.
-- المواعيد بالساعة: open_hour..close_hour (close ممكن > 24 = بعد نص الليل، مثلًا 26 = 2 الفجر).
alter table public.venues add column if not exists lat        double precision;
alter table public.venues add column if not exists lng        double precision;
alter table public.venues add column if not exists phone      text;
alter table public.venues add column if not exists address    text;
alter table public.venues add column if not exists open_hour  int not null default 16;
alter table public.venues add column if not exists close_hour int not null default 24;
alter table public.venues add column if not exists photos     text[] not null default '{}';
alter table public.venues add column if not exists owner_id   uuid references public.profiles(id) on delete set null;
-- لينك جوجل مابس للملعب (الأدق — زرار "الموقع" بيفتحه على طول)
alter table public.venues add column if not exists maps_url   text;
do $$ begin
  alter table public.venues add constraint venues_hours_chk
    check (open_hour between 0 and 23 and close_hour > open_hour and close_hour <= 30);
exception when duplicate_object then null; end $$;

-- الحجوزات: كل صف = ساعة في ملعب في يوم.
create table if not exists public.bookings (
  id         uuid primary key default gen_random_uuid(),
  venue_id   uuid not null references public.venues(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  day        date not null,
  hour       int  not null,                     -- ساعة البداية (≥24 = بعد نص الليل)
  status     text not null default 'pending',   -- pending | confirmed | rejected | cancelled
  note       text,                              -- اسم الفريق / ملاحظة
  created_at timestamptz not null default now()
);
-- الميعاد مايتحجزش مرتين: طلب واحد (معلّق أو مؤكد) بس لكل ملعب+يوم+ساعة.
create unique index if not exists bookings_one_active_per_slot
  on public.bookings (venue_id, day, hour) where status in ('pending', 'confirmed');

alter table public.bookings enable row level security;

-- الكل يشوف الحجوزات (عشان المواعيد المحجوزة تبان)
drop policy if exists "bookings read" on public.bookings;
create policy "bookings read" on public.bookings for select to authenticated using (true);

-- اليوزر يطلب حجز لنفسه بس، معلّق، في يوم جاي، وفي ساعة جوه مواعيد الملعب.
drop policy if exists "bookings request" on public.bookings;
create policy "bookings request" on public.bookings for insert to authenticated
  with check (
    auth.uid() = user_id and status = 'pending' and day >= current_date
    and exists (select 1 from public.venues v
                where v.id = venue_id and hour >= v.open_hour and hour < v.close_hour)
  );
-- مفيش update/delete مباشر — تغيير الحالة بالدالة تحت بس.

-- ساعة بالعربي: 21 → "9:00م"، 24 → "12:00ص"
create or replace function public.fmt_hour(h int)
returns text language sql immutable as $$
  select (case when h % 24 = 0 then 12 when h % 24 > 12 then h % 24 - 12 else h % 24 end)::text
         || ':00' || case when h % 24 < 12 then 'ص' else 'م' end;
$$;

-- تغيير حالة حجز بصلاحيات مضبوطة:
--   صاحب الحجز: يلغي (من معلّق/مؤكد).
--   صاحب الملعب أو المدير: يأكّد/يرفض المعلّق، أو يلغي المؤكد.
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

-- إشعارات جوه التطبيق للحجز (تلقائي من الداتابيز):
--   طلب جديد → صاحب الملعب · تأكيد/رفض → الحاجز · إلغاء → الطرف التاني.
create or replace function public.trg_booking_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare v public.venues; who text; slot text;
begin
  select * into v from public.venues where id = new.venue_id;
  slot := v.name || ' · ' || to_char(new.day, 'DD/MM') || ' الساعة ' || public.fmt_hour(new.hour);
  select coalesce(nullif(name, ''), email) into who from public.profiles where id = new.user_id;

  if tg_op = 'INSERT' then
    if v.owner_id is not null then
      insert into public.notifications (title, body, kind, user_id)
      values ('طلب حجز جديد 📅', who || ' عايز يحجز ' || slot, 'booking', v.owner_id);
    end if;
  elsif new.status is distinct from old.status then
    if new.status = 'confirmed' then
      insert into public.notifications (title, body, kind, user_id)
      values ('اتأكد حجزك ✅', slot, 'booking', new.user_id);
    elsif new.status = 'rejected' then
      insert into public.notifications (title, body, kind, user_id)
      values ('اترفض طلب الحجز ❌', slot, 'booking', new.user_id);
    elsif new.status = 'cancelled' then
      if auth.uid() = new.user_id and v.owner_id is not null then
        insert into public.notifications (title, body, kind, user_id)
        values ('اتلغى حجز 🚫', who || ' لغى ' || slot, 'booking', v.owner_id);
      elsif auth.uid() is distinct from new.user_id then
        insert into public.notifications (title, body, kind, user_id)
        values ('اتلغى حجزك 🚫', slot, 'booking', new.user_id);
      end if;
    end if;
  end if;
  return new;
end; $$;
drop trigger if exists booking_notify on public.bookings;
create trigger booking_notify
after insert or update on public.bookings
for each row execute function public.trg_booking_notify();

do $$ begin
  alter publication supabase_realtime add table public.bookings;
exception when duplicate_object then null; end $$;

-- Realtime لباقي الجداول اللي اليوزر بيشوفها (أي تعديل من المدير يظهر عند الكل فورًا)
do $$
declare t text;
begin
  foreach t in array array['lineups', 'players', 'events', 'polls', 'venues', 'picks'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

-- ── صور الملاعب (Supabase Storage) — الكل يشوف، المدير بس يرفع/يمسح ──
insert into storage.buckets (id, name, public)
values ('venue-photos', 'venue-photos', true)
on conflict (id) do nothing;

drop policy if exists "venue photos read" on storage.objects;
create policy "venue photos read" on storage.objects
  for select using (bucket_id = 'venue-photos');
drop policy if exists "venue photos manager upload" on storage.objects;
create policy "venue photos manager upload" on storage.objects
  for insert to authenticated with check (bucket_id = 'venue-photos' and public.is_manager());
drop policy if exists "venue photos manager delete" on storage.objects;
create policy "venue photos manager delete" on storage.objects
  for delete to authenticated using (bucket_id = 'venue-photos' and public.is_manager());


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 10) FCM                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

alter table public.profiles add column if not exists fcm_token text;


-- ═══════════════════════════════════════════════════════════════
-- خلصنا. (اختياري) خلّي نفسك مدير — بدّل الإيميل بإيميلك:
--   update public.profiles set role = 'manager' where email = 'you@email.com';
-- ═══════════════════════════════════════════════════════════════
