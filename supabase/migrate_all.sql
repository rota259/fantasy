-- ═══════════════════════════════════════════════════════════════
-- الخماسي — كل الـ migrations في ملف واحد (شغّله مرة واحدة)
-- Supabase Dashboard → SQL Editor → New query → الصق الكل → Run
--
-- الترتيب مهم ومظبوط هنا:
--   1) schema            — الجداول + RLS + بيانات تجريبية
--   2) manager & scoring — دور المدير + محرك النقاط + fn_event_points
--   3) lineups           — تشكيلة كل ماتش (المدير)
--   4) picks             — اختيار اليوزر لكل ماتش + إعادة حساب النقاط (النموذج الجديد)
--   5) team of week      — نقاط اللاعيبة في الجولة
--   6) fcm               — عمود توكن الإشعارات
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
  yellow_cards  int not null default 0
);

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

-- تفعيل الـ Realtime للمزاد (idempotent) — بدون أي بيانات
do $$ begin
  alter publication supabase_realtime add table public.auction_bids;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.auctions;
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

-- ── إعادة حساب نقاط لاعب من أحداثه ──
create or replace function public.fn_recalc_player(p_player uuid)
returns void language sql as $$
  update public.players pl
  set total_points = coalesce((
    select sum(public.fn_event_points(e.type, pl.position))
    from public.events e where e.player_id = pl.id
  ), 0)
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

-- ═══ إعادة حساب نقاط المستخدمين من اختيارات الماتشات ═══
-- الأساسيين فقط. الكابتن ×2 لو لعب؛ لو الكابتن ملعبش → الكابتن الاحتياطي ×2.
create or replace function public.fn_recalc_users()
returns void language sql as $$
  update public.profiles pr set total_points = coalesce((
    select sum(
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
    )
    from public.picks pk
    join public.players pl on pl.id = pk.player_id
    where pk.user_id = pr.id and pk.status = 'starting'
  ), 0);
$$;

-- تريجر: أي تغيير في events → أعد حساب اللاعب + كل المستخدمين
create or replace function public.trg_events_recalc()
returns trigger language plpgsql as $$
begin
  perform public.fn_recalc_player(coalesce(new.player_id, old.player_id));
  perform public.fn_recalc_users();
  return null;
end;
$$;
drop trigger if exists events_recalc on public.events;
create trigger events_recalc
after insert or update or delete on public.events
for each row execute function public.trg_events_recalc();

-- تريجر: أي تغيير في picks → أعد حساب النقاط
create or replace function public.trg_picks_recalc()
returns trigger language plpgsql as $$
begin
  perform public.fn_recalc_users();
  return null;
end; $$;
drop trigger if exists picks_recalc on public.picks;
create trigger picks_recalc
after insert or update or delete on public.picks
for each row execute function public.trg_picks_recalc();

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


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 6) FCM                                                         ║
-- ╚═══════════════════════════════════════════════════════════════╝

alter table public.profiles add column if not exists fcm_token text;


-- ═══════════════════════════════════════════════════════════════
-- خلصنا. (اختياري) خلّي نفسك مدير — بدّل الإيميل بإيميلك:
--   update public.profiles set role = 'manager' where email = 'you@email.com';
-- ═══════════════════════════════════════════════════════════════
