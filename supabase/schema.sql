-- ═══════════════════════════════════════════════════════════════
-- الخماسي — Supabase schema
-- الصقه في: Supabase Dashboard → SQL Editor → New query → Run
-- الأعمدة snake_case ومطابقة للموديلز في lib/features/*/data/models
-- ═══════════════════════════════════════════════════════════════

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
  current_player_id uuid references public.players(id),
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

-- ═══════════════════════════════════════════════════════════════
-- دالة آمنة: تحويل رقم الموبايل → إيميل (للدخول بالرقم قبل المصادقة)
-- SECURITY DEFINER عشان تتجاوز RLS بأمان من غير ما تكشف الجدول.
-- ═══════════════════════════════════════════════════════════════
create or replace function public.email_for_phone(p text)
returns text
language sql
security definer
set search_path = public
as $$
  select email from public.profiles where phone = p limit 1;
$$;
grant execute on function public.email_for_phone(text) to anon, authenticated;

-- ═══════════════════════════════════════════════════════════════
-- Row Level Security
-- ═══════════════════════════════════════════════════════════════
alter table public.profiles       enable row level security;
alter table public.players        enable row level security;
alter table public.matches        enable row level security;
alter table public.leagues        enable row level security;
alter table public.league_members enable row level security;
alter table public.venues         enable row level security;
alter table public.auctions       enable row level security;
alter table public.auction_bids   enable row level security;
alter table public.events         enable row level security;

-- profiles: الكل يقرأ (للترتيب)، وكل واحد يعدّل صفّه بس
create policy "profiles read"   on public.profiles for select to authenticated using (true);
create policy "profiles insert" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles update" on public.profiles for update to authenticated using (auth.uid() = id);

-- players / matches / events: قراءة للجميع، والكتابة من لوحة التحكم/السيرفر فقط
create policy "players read" on public.players for select to authenticated using (true);
create policy "matches read" on public.matches for select to authenticated using (true);
create policy "events read"  on public.events  for select to authenticated using (true);
create policy "venues read"  on public.venues  for select to authenticated using (true);

-- auctions: قراءة للجميع؛ المزايدات قراءة للجميع + كل واحد يزايد باسمه
create policy "auctions read" on public.auctions for select to authenticated using (true);
create policy "bids read"     on public.auction_bids for select to authenticated using (true);
create policy "bids insert"   on public.auction_bids for insert to authenticated with check (auth.uid() = user_id);

-- leagues: قراءة + إنشاء
create policy "leagues read"   on public.leagues for select to authenticated using (true);
create policy "leagues insert" on public.leagues for insert to authenticated with check (true);

-- league_members: قراءة للجميع، وكل واحد يضيف/يشيل عضويته بس
create policy "members read"   on public.league_members for select to authenticated using (true);
create policy "members insert" on public.league_members for insert to authenticated with check (auth.uid() = user_id);
create policy "members delete" on public.league_members for delete to authenticated using (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- بيانات تجريبية (اختياري) — عشان السوق يبان ببيانات حقيقية فورًا
-- ═══════════════════════════════════════════════════════════════
insert into public.players (name, team, position, price, total_points, form) values
  ('أحمد فتحي',   'التجمع',     'FWD', 8.5, 189, 8.4),
  ('مصطفى وائل',  'المهندسين',  'MID', 7.1, 172, 7.1),
  ('طارق سمير',   'أكتوبر',     'FWD', 5.2, 141, 8.6),
  ('كريم حسن',    'المعادي',    'DEF', 5.5, 128, 6.0),
  ('حسام عادل',   'الرحاب',     'GK',  4.8, 119, 5.3),
  ('زياد ناصر',   'مدينة نصر',  'DEF', 4.8,  96, 2.1)
on conflict do nothing;

insert into public.matches (date_time, teams, week, status, fdr) values
  (now() + interval '2 day' + interval '21 hour', array['التجمع','أكتوبر'],        7, 'upcoming', 2),
  (now() + interval '2 day' + interval '21 hour', array['المهندسين','الرحاب'],     7, 'upcoming', 3),
  (now() + interval '2 day' + interval '22 hour', array['المعادي','مدينة نصر'],    7, 'upcoming', 5),
  (now() + interval '3 day' + interval '19 hour', array['أكتوبر','الشيخ زايد'],    7, 'upcoming', 2),
  (now() + interval '3 day' + interval '21 hour', array['الرحاب','الزمالك سبورت'], 7, 'upcoming', 4)
on conflict do nothing;

-- دوري تجريبي — انضم له من التطبيق بالكود SHILLA7
insert into public.leagues (name, type, invite_code) values
  ('دوري الشلّة', 'h2h', 'SHILLA7')
on conflict do nothing;

insert into public.venues (name, price, distance_km, surface, feature, capacity, filled, slot_time) values
  ('ملعب التجمع الخماسي', 120, 1.2, 'نجيلة صناعية', 'إضاءة',  10, 6,  '9:00م'),
  ('أرينا المعادي',       150, 3.4, 'نجيلة صناعية', 'مغطّى',   10, 10, '9:00م'),
  ('ستاد أكتوبر 6',       100, 5.1, 'نجيلة صناعية', null,      10, 2,  '10:30م')
on conflict do nothing;

-- ═══ تفعيل الـ Realtime للمزاد (idempotent) ═══
do $$ begin
  alter publication supabase_realtime add table public.auction_bids;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.auctions;
exception when duplicate_object then null; end $$;

-- مزاد تجريبي على أحمد فتحي (لو مفيش مزاد شغّال)
insert into public.auctions (name, current_player_id, base_price, ends_at, status)
select 'شلة الجمعة', p.id, 6, now() + interval '2 minute', 'live'
from public.players p
where p.name = 'أحمد فتحي'
  and not exists (select 1 from public.auctions where status = 'live')
limit 1;
