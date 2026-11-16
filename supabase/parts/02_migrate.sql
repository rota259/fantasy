-- الجزء 2 من 7 — شغّل الأجزاء بالترتيب (اتعمل من migrate_all.sql بـ tool/split_sql.py)
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
    auth.uid() = user_id and status = 'pending' and day >= current_date and day <= current_date + 30
    -- بحد ٣ طلبات مستنية في نفس الوقت (محدش يحجز ملعب كله)
    and (select count(*) from public.bookings b where b.user_id = auth.uid() and b.status = 'pending') < 3
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
-- الأدمن يمسح أي تقييم مسيء
drop policy if exists "reviews manager delete" on public.venue_reviews;
create policy "reviews manager delete" on public.venue_reviews for delete to authenticated using (public.is_manager());

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
-- كارت واحد بس في الجولة (week_cutoff = نهاية الجولة) ومبيتلغيش. match_id للكروت القديمة بس.
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
do $$ begin
  alter table public.chip_uses drop constraint chip_uses_pkey;
exception when undefined_object then null; end $$;
alter table public.chip_uses alter column match_id drop not null;
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

-- حالة الكروت لجولة (للشاشة): المستخدم، الحد، مفعّل فيها، وسبب المنع لو ممنوع.
drop function if exists public.chip_status(uuid);
create or replace function public.chip_status(p_round timestamptz)
returns table(chip text, used int, lim int, active boolean, blocked text)
language plpgsql stable security definer set search_path = public as $$
declare st timestamptz := p_round - interval '7 days'; s public.seasons; h int; here text; has_picks boolean;
begin
  s := public.fn_season_at(st);
  select c.chip into here from public.chip_uses c where c.user_id = auth.uid() and c.week_cutoff = p_round;
  has_picks := exists(select 1 from public.round_picks p where p.user_id = auth.uid() and p.round_end = p_round);
  if s.id is not null then
    h := case when st < s.mid_at then 1 else 2 end;
  end if;

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
      when s.id is null then 'مفيش موسم شغّال'
      when k.chip = 'wildcard' and now() >= public.fn_round_start(p_round) and not public.fn_test_mode() then 'الجولة بدأت'
      when k.chip <> 'wildcard' and now() >= public.fn_round_deadline(p_round) then 'التشكيلة اتقفلت'
      when not has_picks then 'احفظ تشكيلتك الأول'
      else null end
  from (values ('triple'), ('bench_boost'), ('wildcard'), ('double')) as k(chip);
end $$;
grant execute on function public.chip_status(timestamptz) to authenticated;


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
  or exists (select 1 from public.matches m where m.id = match_id and m.date_time <= now()
             and m.zone_id = (select p.zone_id from public.profiles p where p.id = auth.uid()))
);
drop policy if exists "predictions own write" on public.predictions;
create policy "predictions own write" on public.predictions for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and exists (
    select 1 from public.matches m where m.id = match_id and m.is_challenge
      and not public.fn_is_zone_manager()
      and m.zone_id = (select p.zone_id from public.profiles p where p.id = auth.uid())
      and m.status = 'upcoming' and (public.fn_test_mode() or now() < m.date_time - public.fn_lock_lead())));

-- (مدير المنطقة من ماتشاته، أو الأدمن) يعلن ماتش تحدّي الجولة — لأهل منطقة الماتش بس.
-- كل مدير تحدّي واحد في الجولة. اللي يتوقّع فرق الأهداف صح ياخد +٥.
create or replace function public.set_challenge(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
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
  if exists (select 1 from public.matches x
             where x.is_challenge and x.organizer_id is not distinct from m.organizer_id and x.id <> m.id
               and public.fn_week_cutoff(x.date_time) = public.fn_week_cutoff(m.date_time)) then
    raise exception 'فيه تحدّي من ماتشات المدير ده في الجولة دي خلاص';
  end if;
  update public.matches set is_challenge = true where id = p_match;
  perform public.fn_notify_match(p_match, '🎯 تحدّي الجولة',
    'توقّع فرق الأهداف في ' || m.teams[1] || ' ضد ' || m.teams[2] || ' صح واكسب +٥ نقط', 'challenge');
end $$;
grant execute on function public.set_challenge(uuid) to authenticated;

-- ملخص التوقعات بعد الماتش: كام واحد توقّع، وكام جابها صح
create or replace function public.challenge_summary(p_match uuid)
returns table(total bigint, correct bigint)
language sql stable security definer set search_path = public as $$
  select count(*), count(*) filter (where p.score_a - p.score_b = m.score_a - m.score_b)
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
  or (audience = 'zone' and zone_id = (select p.zone_id from public.profiles p where p.id = auth.uid()))
  or (audience = 'match' and exists (select 1 from public.match_follows f
        where f.match_id = notifications.match_id and f.user_id = auth.uid()))
);

-- كل حدث بيتسجّل → إشعار لمتابعين الماتش
create or replace function public.trg_event_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare m public.matches; pn text;
begin
  if new.type in ('save', 'tackle') then return new; end if;
  select * into m from public.matches where id = new.match_id;
  select name into pn from public.players where id = new.player_id;
  if new.type = 'sub' then
    pn := coalesce(pn, '') || ' مكان ' || coalesce((select name from public.players where id = new.other_player_id), '');
  end if;
  insert into public.notifications (title, body, kind, match_id, audience)
  values (public.fn_event_label(new.type) || ' — ' || coalesce(pn, ''),
          case when new.type in ('goal', 'ownGoal')
               then (select m.teams[1] || ' ' || s.a || ' - ' || s.b || ' ' || m.teams[2] from public.fn_match_score(m.id) s)
               else m.teams[1] || ' ضد ' || m.teams[2] end
          || coalesce(' · الدقيقة ' || new.minute, ''),
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
    and m.finished_at is not null and m.finished_at > now() - public.fn_rating_window() and not m.motm_done);
$$;

drop policy if exists "ratings read own" on public.player_ratings;
create policy "ratings read own" on public.player_ratings for select to authenticated
  using (user_id = auth.uid() or public.is_manager());
drop policy if exists "ratings own write" on public.player_ratings;
create policy "ratings own write" on public.player_ratings for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and not public.fn_is_zone_manager() and public.fn_rating_open(match_id)
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
             and finished_at <= now() - public.fn_rating_window() loop
    w := null;
    select pr.player_id into w from public.player_ratings pr where pr.match_id = r.id
      group by pr.player_id order by avg(pr.rating) desc, count(*) desc limit 1;
    update public.matches set motm_done = true, motm_player_id = w where id = r.id;
    if w is not null then
      select name into wn from public.players where id = w;
      insert into public.events (match_id, player_id, type) values (r.id, w, 'motm');
      perform public.fn_notify_match(r.id, '⭐ رجل المباراة: ' || wn,
        r.teams[1] || ' ضد ' || r.teams[2] || ' · +٣ نقط بتصويت الجمهور', 'match');
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
  user_id = auth.uid() and status = 'pending' and not public.fn_is_zone_manager()
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
    (select count(distinct rp.user_id) from public.round_picks rp
     where rp.player_id = p_player and rp.is_captain and rp.round_end > p_from and rp.round_end <= p_to),
    me.managers, me.ownership,
    (select count(*) + 1 from pos where pos.ownership > me.ownership),
    (select count(*) from pos),
    (select coalesce(sum(x.base * case when rp.is_captain then 2 else 1 end), 0)
     from public.round_picks rp
     cross join lateral (
       select coalesce(sum(y.points), 0) as base
       from public.fn_pmp(public.fn_round_from(rp.round_end), rp.round_end, rp.player_id) y) x
     where rp.player_id = p_player and rp.status = 'starting'
       and rp.round_end > (select t from since))::bigint
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
      coalesce((select sum(y.points) from public.fn_pmp('-infinity', 'infinity', pk.player_id) y
                where y.match_id = p_match), 0) as base,
      exists (select 1 from public.fn_pmp('-infinity', 'infinity', pk.player_id) y where y.match_id = p_match) as played
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
    and (m.review_status = 'approved' or public.fn_test_mode())
    and pr.score_a - pr.score_b = m.score_a - m.score_b;
$$;

-- نقط تشكيلة يوزرز في جولة — في query واحدة (مع كل جول ممكن آلاف اليوزرز يتأثروا).
-- نفس LineupPoints في Dart بالظبط:
--   نقط كل لاعب = مجموع أحداثه في كل ماتشات الجولة · points = مباشر (غير الملغي) · final_points = المعتمد بس
--   الأساسيين بس (إلا مع bench_boost الكل) · الكابتن ×٢ لو لعب في الجولة، ولو ملعبش البديل ×٢
--   triple → المضاعف ×٣ · double → المجموع كله ×٢
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
           bool_or(rp.is_captain and rp.played_fin) as cap_fin
    from rp group by rp.user_id
  )
  select rp.user_id,
    (coalesce(sum(rp.live * case
        when (rp.is_captain and cap.cap_live) or (rp.is_vice and not cap.cap_live)
          then case when rp.chip = 'triple' then 3 else 2 end else 1 end)
      filter (where rp.status = 'starting' or rp.chip = 'bench_boost'), 0)
      * case when max(rp.chip) = 'double' then 2 else 1 end)::int,
    (coalesce(sum(rp.fin * case
        when (rp.is_captain and cap.cap_fin) or (rp.is_vice and not cap.cap_fin)
          then case when rp.chip = 'triple' then 3 else 2 end else 1 end)
      filter (where rp.status = 'starting' or rp.chip = 'bench_boost'), 0)
      * case when max(rp.chip) = 'double' then 2 else 1 end)::int
  from rp join cap on cap.user_id = rp.user_id
  group by rp.user_id;
$$;

-- نقط يوزر واحد في جولة (نفس الحسبة)
create or replace function public.fn_user_round_points(p_user uuid, p_round timestamptz, p_final boolean)
returns int language sql stable security definer set search_path = public as $$
  select coalesce((select case when p_final then b.final_points else b.points end
                   from public.fn_round_points_bulk(p_round, array[p_user]) b), 0);
$$;

-- إجمالي نقاط اليوزر = المعتمد من الجولات + ماتشات النظام القديم المعتمدة + البونص
-- إجمالي اليوزر (الدوري العام والترتيب) = مجموع نقط كل جولاته + بونص التوقعات.
-- المعتمد بس — وفي وضع التجربة كل النقط على طول (من غير ما تستنى الاعتماد)
create or replace function public.fn_user_points(p_user uuid)
returns int language sql stable security definer set search_path = public as $$
  select (coalesce((select sum(case when public.fn_test_mode() then r.points else r.final_points end)
                    from public.user_round_points r where r.user_id = p_user), 0)
          + coalesce((select sum(u.points) from public.user_match_points u
                      join public.matches m on m.id = u.match_id
                      where u.user_id = p_user and m.review_status = 'approved'), 0)
          + public.fn_user_bonus(p_user))::int;
$$;

create or replace function public.fn_recalc_user_round(p_user uuid, p_round timestamptz)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_recalc_round_users(p_round, array[p_user]);
end $$;

-- نقط يوزرز في جولة + إجماليهم — كله set-based
create or replace function public.fn_recalc_round_users(p_round timestamptz, p_users uuid[])
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_round is null or p_users is null or cardinality(p_users) = 0 then return; end if;
  insert into public.user_round_points (user_id, round_end, points, final_points)
  select b.user_id, p_round, b.points, b.final_points from public.fn_round_points_bulk(p_round, p_users) b
  on conflict (user_id, round_end) do update
    set points = excluded.points, final_points = excluded.final_points;
  -- اللي شال تشكيلته
  delete from public.user_round_points u
  where u.round_end = p_round and u.user_id = any(p_users)
    and not exists (select 1 from public.round_picks rp where rp.user_id = u.user_id and rp.round_end = p_round);
  update public.profiles set total_points = public.fn_user_points(id), badges_dirty = true
  where id = any(p_users);
end $$;

-- نقط كل اللي اختاروا لاعيبة معيّنة في جولة (بعد حدث أو اعتماد ماتش)
create or replace function public.fn_recalc_round_players(p_round timestamptz, p_players uuid[])
returns void language plpgsql security definer set search_path = public as $$
declare users uuid[];
begin
  if p_round is null then return; end if;
  select array_agg(distinct user_id) into users
  from public.round_picks where round_end = p_round and player_id = any(p_players);
  perform public.fn_recalc_round_users(p_round, users);
end $$;

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
  insert into public.user_round_points (user_id, round_end, points, final_points)
  select b.user_id, r.round_end, b.points, b.final_points
  from (select round_end, array_agg(distinct user_id) as users from public.round_picks group by round_end) r
  cross join lateral public.fn_round_points_bulk(r.round_end, r.users) b
  on conflict (user_id, round_end) do update
    set points = excluded.points, final_points = excluded.final_points;
  update public.profiles set total_points = public.fn_user_points(id) where id is not null;
end $$;

-- أي تغيير في الأحداث → إحصائيات اللاعب + نقط اللي اختاروه في الجولة (+ الماتش القديم لو ليه تشكيلات)
create or replace function public.trg_events_recalc()
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
    if tg_op = 'INSERT' or new.match_id is distinct from old.match_id then
      perform public.fn_recalc_match(new.match_id);
    end if;
    perform public.fn_recalc_round_players(
      public.fn_week_cutoff((select date_time from public.matches where id = new.match_id)), array[new.player_id]);
  end if;
  return null;
end $$;
drop trigger if exists events_recalc on public.events;
create trigger events_recalc after insert or update or delete on public.events
for each row execute function public.trg_events_recalc();

-- الاعتماد اتغيّر (أو النتيجة اتعدّلت بعد الاعتماد) → إجمالي نقط اللي لعبوا/توقّعوا
-- + أول ما ماتش التحدّي يتعتمد: إشعار للي توقّعوا صح
create or replace function public.trg_match_result()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- النتيجة/الحالة اتغيّرت → كلين شيت الحراس + نقط الجولة
  if (new.status, new.score_a, new.score_b) is distinct from (old.status, old.score_a, old.score_b) then
    perform public.fn_recalc_player(l.player_id) from public.lineups l
      join public.players pl on pl.id = l.player_id and pl.position = 'GK' where l.match_id = new.id;
    perform public.fn_recalc_round_players(public.fn_week_cutoff(new.date_time),
      array(select id from public.players where team = any(new.teams)));
  end if;
  if new.review_status is distinct from old.review_status
     or (new.review_status = 'approved' and (new.score_a, new.score_b, new.is_challenge)
           is distinct from (old.score_a, old.score_b, old.is_challenge)) then
    update public.profiles set total_points = public.fn_user_points(id), badges_dirty = true
    where id in (select user_id from public.picks where match_id = new.id
                 union select user_id from public.predictions where match_id = new.id);
    -- تشكيلات الجولة: كل اللي اختاروا حد من لاعيبة الفريقين
    perform public.fn_recalc_round_players(public.fn_week_cutoff(new.date_time),
      array(select id from public.players where team = any(new.teams)));
    if new.is_challenge and new.review_status = 'approved' and old.review_status is distinct from 'approved' then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🎯 توقّعت فرق الأهداف صح! +٥', new.teams[1] || ' ' || new.score_a || ' - ' || new.score_b || ' ' || new.teams[2],
             'challenge', p.user_id, new.id
      from public.predictions p
      where p.match_id = new.id and p.score_a - p.score_b = new.score_a - new.score_b;
    end if;
  end if;
  return null;
end $$;
drop trigger if exists match_result on public.matches;
create trigger match_result after update on public.matches
for each row execute function public.trg_match_result();

-- حفظ تشكيلة الجولة (استبدال كامل في transaction واحدة) + التحقّق من القواعد في السيرفر:
-- ٧ لاعيبة من منطقتك: ٥ أساسي (حارس واحد) + ٢ احتياطي + كابتن + كابتن بديل (من الأساسيين).
-- مفتوحة لحد ديدلاين الجولة (السبت ٣ العصر)، أو بالوايلد كارد لحد ما الجولة تبدأ (٤ العصر).
drop function if exists public.save_picks(uuid, jsonb);
drop function if exists public.fn_can_edit_picks(uuid);
create or replace function public.save_round_picks(p_round timestamptz, p_picks jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); z int;
        n_start int; n_bench int; n_gk int; n_cap int; n_vice int; n_bad int; n_dup int; n_zone int; n_mine int;
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  perform public.fn_assert_active();
  if public.fn_is_zone_manager() then raise exception 'حساب المدير مش بيلعب فانتازي — اعمل حساب تاني لو عايز تلعب'; end if;
  if jsonb_typeof(p_picks) <> 'array' then raise exception 'بيانات غلط'; end if;
  if public.fn_week_cutoff(p_round) is distinct from p_round then raise exception 'جولة غلط'; end if;
  if p_round > public.fn_open_round() + interval '7 days' then raise exception 'الجولة دي لسه بعيدة'; end if;
  if not (now() < public.fn_round_deadline(p_round)
          or (now() < public.fn_round_start(p_round) and exists (select 1 from public.chip_uses c
                where c.user_id = u and c.week_cutoff = p_round and c.chip = 'wildcard'))) then
    raise exception 'التشكيلة اتقفلت — ديدلاين الجولة (السبت ٣ العصر) عدّى';
  end if;
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
  if n_mine > 0 then raise exception 'مينفعش تختار لاعيبة من فرقك انت كمدير'; end if;
  if n_start <> 5 then raise exception 'لازم ٥ أساسيين بالظبط'; end if;
  if n_bench <> 2 then raise exception 'لازم ٢ احتياطي'; end if;
  if n_gk <> 1 then raise exception 'لازم حارس واحد في الأساسيين'; end if;
  if n_cap <> 1 then raise exception 'اختار كابتن من الأساسيين'; end if;
  if n_vice <> 1 then raise exception 'اختار كابتن بديل من الأساسيين'; end if;

  delete from public.round_picks where user_id = u and round_end = p_round;
  insert into public.round_picks (user_id, round_end, player_id, status, is_captain, is_vice, saved_at)
  select u, p_round, x.player_id, x.status, coalesce(x.is_captain, false), coalesce(x.is_vice, false), now()
  from jsonb_to_recordset(p_picks) as x(player_id uuid, status text, is_captain boolean, is_vice boolean);
  perform public.fn_recalc_user_round(u, p_round);
end $$;
grant execute on function public.save_round_picks(timestamptz, jsonb) to authenticated;

-- تفعيل كارت على جولة (مبيتلغيش): قبل الديدلاين، والوايلد كارد لحد ما الجولة تبدأ
drop function if exists public.activate_chip(uuid, text);
create or replace function public.activate_chip(p_round timestamptz, p_chip text)
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); st timestamptz := p_round - interval '7 days'; s public.seasons; h int; used int;
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  perform public.fn_assert_active();
  if p_chip not in ('triple', 'bench_boost', 'wildcard', 'double') then raise exception 'كارت مش معروف'; end if;
  if public.fn_is_zone_manager() then raise exception 'حساب المدير مش بيلعب فانتازي'; end if;
  if public.fn_week_cutoff(p_round) is distinct from p_round then raise exception 'جولة غلط'; end if;
  perform pg_advisory_xact_lock(hashtext(u::text));
  if p_chip = 'wildcard' then
    if now() >= public.fn_round_start(p_round) and not public.fn_test_mode() then raise exception 'الجولة بدأت'; end if;
  elsif now() >= public.fn_round_deadline(p_round) then
    raise exception 'التشكيلة اتقفلت — الكارت لازم يتفعّل قبل الديدلاين';
  end if;
  if not exists (select 1 from public.round_picks where user_id = u and round_end = p_round) then
    raise exception 'احفظ تشكيلتك للجولة دي الأول';
  end if;
  s := public.fn_season_at(st);
  if s.id is null then raise exception 'مفيش موسم شغّال — المدير لازم يحدّد مواعيد الموسم'; end if;
  h := case when st < s.mid_at then 1 else 2 end;
  if exists (select 1 from public.chip_uses where user_id = u and week_cutoff = p_round) then
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
  insert into public.chip_uses (user_id, chip, season_id, half, week_cutoff)
  values (u, p_chip, s.id, h, p_round);
  perform public.fn_recalc_user_round(u, p_round);
end $$;
grant execute on function public.activate_chip(timestamptz, text) to authenticated;

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
-- كام دوري أنا عامله (دالة لوحدها: لو السياسة سألت جدول leagues نفسه بتدخل في infinite recursion
-- وإنشاء الدوري بيفشل)
create or replace function public.fn_my_league_count()
returns bigint language sql stable security definer set search_path = public as $$
  select count(*) from public.leagues where owner_id = auth.uid();
$$;
grant execute on function public.fn_my_league_count() to authenticated;

drop policy if exists "leagues insert" on public.leagues;
create policy "leagues insert" on public.leagues for insert to authenticated with check (
  owner_id = auth.uid() and type <> 'global' and not public.fn_is_zone_manager()
  and (public.is_manager() or public.fn_my_league_count() < 10)
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
  if public.fn_is_zone_manager() then raise exception 'حساب المدير مش بيدخل دوريات'; end if;
  perform public.fn_assert_active();
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
    case when mine.type = 'global' then (select count(*) from public.profiles where role <> 'organizer' and is_active)
         else (select count(*) from public.league_members m where m.league_id = mine.id) end,
    1 + (select count(*) from public.profiles p, me
         where p.role <> 'organizer' and p.is_active and (mine.type = 'global'
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

-- كسر التعادل: كام لاعب أساسي اخترته وامتلاكه في منطقتك في الجولة كان أقل من ٢٥٪ (الأكتر فوق)،
-- ولو لسه متعادلين: متوسط امتلاك اختياراتك الأقل فوق. (الجولات اللي ديدلاينها عدّى بس)
create or replace function public.fn_user_tiebreak()
returns table(user_id uuid, low_picks bigint, avg_own numeric)
language sql stable security definer set search_path = public as $$
  with rp as (
    select rp.user_id, rp.round_end, rp.player_id, rp.status, pr.zone_id
    from public.round_picks rp join public.profiles pr on pr.id = rp.user_id
    where public.fn_round_deadline(rp.round_end) <= now()
  ), tot as (
    select rp.round_end, rp.zone_id, count(distinct rp.user_id)::numeric as n from rp group by rp.round_end, rp.zone_id
  ), own as (
    select rp.round_end, rp.zone_id, rp.player_id, count(*)::numeric as n from rp
    group by rp.round_end, rp.zone_id, rp.player_id
  ), mine as (
    select rp.user_id, own.n * 100 / tot.n as pct
    from rp
    join tot on tot.round_end = rp.round_end and tot.zone_id is not distinct from rp.zone_id
    join own on own.round_end = rp.round_end and own.zone_id is not distinct from rp.zone_id
            and own.player_id = rp.player_id
    where rp.status = 'starting'
  )
  select mine.user_id, count(*) filter (where mine.pct < 25), round(avg(mine.pct), 1)
  from mine group by mine.user_id;
$$;

-- بيتنادي من fn_tick: أول ما جولة تبدأ، كسر التعادل يتحدّث لليوزرز اللي لعبوها (مرة واحدة)
create or replace function public.fn_update_tiebreak()
returns void language plpgsql security definer set search_path = public as $$
declare r timestamptz := public.fn_week_cutoff(now());
begin
  insert into public.app_jobs (key) values ('tiebreak:' || to_char(r at time zone 'UTC', 'YYYYMMDDHH24'))
  on conflict do nothing;
  if not found then return; end if;
  update public.profiles p set low_picks = t.low_picks, avg_own = t.avg_own
  from public.fn_user_tiebreak() t
  where p.id = t.user_id
    and p.id in (select distinct rp.user_id from public.round_picks rp where rp.round_end = r);
end $$;

-- ترتيب دوري: النقط ثم كسر التعادل (المتعادلين بالظبط لهم نفس المركز). العام = كل اليوزرز.
drop function if exists public.league_standings(uuid);
drop function if exists public.league_standings(uuid, int, int);
create or replace function public.league_standings(p_league uuid, p_offset int default 0, p_limit int default 50)
returns table(rank bigint, user_id uuid, name text, photo_url text, points int, low_picks int, moved int)
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
  select x.rk, x.id, x.name, x.photo_url, x.total_points, x.low_picks,
         case when l.type = 'global' and x.prev_rank is not null then (x.prev_rank - x.rk)::int end
  from (
    select rank() over (order by p.total_points desc, p.low_picks desc, p.avg_own asc) as rk,
           p.id, p.name, p.photo_url, p.total_points, p.low_picks, p.prev_rank, p.avg_own, p.created_at
    from public.profiles p
    where p.role <> 'organizer' and p.is_active
      and (l.type = 'global' or p.id in (select m.user_id from public.league_members m where m.league_id = l.id))
  ) x
  order by x.total_points desc, x.low_picks desc, x.avg_own asc, x.created_at
  offset greatest(p_offset, 0) limit least(greatest(p_limit, 1), 100);
end $$;
grant execute on function public.league_standings(uuid, int, int) to authenticated;

-- ترتيبي العام = كام واحد أحسن مني + ١
create or replace function public.my_global_rank()
returns bigint language sql stable security definer set search_path = public as $$
  select 1 + count(*) from public.profiles p, public.profiles me
  where me.id = auth.uid() and p.role <> 'organizer' and p.is_active
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
  for r in select id, kind, question, zone_id from public.polls
           where active and closes_at is not null and closes_at <= now() loop
    update public.polls set active = false where id = r.id;
    select label into w from public.poll_options where id = public.fn_poll_winner(r.id);
    insert into public.notifications (title, body, kind, audience, zone_id)
    values (case when r.kind = 'totw_tie' then '⚖️ اتحسم التعادل' else '🏆 ' || r.question end,
            coalesce('الفايز: ' || w, 'التصويت خلص'), 'vote',
            case when r.zone_id is null then 'all' else 'zone' end, r.zone_id);
  end loop;
end $$;

-- تعادل على آخر مكان في تشكيلة الجولة (أعلى ٥) → تصويت لحد نص الليل — لكل منطقة لوحدها
create or replace function public.fn_totw_tie_zone(p_cutoff timestamptz, p_zone int)
returns void language plpgsql security definer set search_path = public as $$
declare ids uuid[]; names text[]; ps bigint[]; above int; slots int; pid uuid;
begin
  if exists (select 1 from public.polls where kind = 'totw_tie' and window_end = p_cutoff
             and zone_id is not distinct from p_zone) then return; end if;
  -- تشكيلة الجولة = أعلى حارس + أعلى ٤ (غير الحراس) → التعادل على آخر مكان من الأربعة
  select array_agg(t.id order by t.points desc, t.name), array_agg(t.name order by t.points desc, t.name),
         array_agg(t.points order by t.points desc, t.name)
  into ids, names, ps
  from public.player_points_between(public.fn_round_from(p_cutoff), p_cutoff, p_zone) t
  where t.points > 0 and t.position <> 'GK';
  if ids is null or array_length(ids, 1) < 5 or ps[4] <> ps[5] then return; end if;
  select count(*) into above from unnest(ps) x where x > ps[4];
  slots := 4 - above;
  insert into public.polls (kind, question, active, window_end, closes_at, slots, zone_id)
  values ('totw_tie', 'تعادل في تشكيلة الجولة — مين يدخل؟', true, p_cutoff,
          p_cutoff + interval '16 hours', slots, p_zone)
  returning id into pid;
  insert into public.poll_options (poll_id, label, player_id)
  select pid, names[i], ids[i] from generate_subscripts(ids, 1) i where ps[i] = ps[4];
  insert into public.notifications (title, body, kind, audience, zone_id)
  values ('⚖️ تعادل في تشكيلة الجولة', 'لاعيبة جابوا نفس النقط على آخر ' ||
          case when slots = 1 then 'مكان' else slots || ' أماكن' end || ' — صوّت لحد نص الليل', 'vote',
          case when p_zone is null then 'all' else 'zone' end, p_zone);
end $$;

create or replace function public.fn_totw_tie(p_cutoff timestamptz)
returns void language plpgsql security definer set search_path = public as $$
declare z record; any_zone boolean := false;
begin
  for z in select distinct m.zone_id from public.matches m
           where m.date_time > public.fn_round_from(p_cutoff) and m.date_time <= p_cutoff and m.zone_id is not null loop
    any_zone := true;
    perform public.fn_totw_tie_zone(p_cutoff, z.zone_id);
  end loop;
  if not any_zone then perform public.fn_totw_tie_zone(p_cutoff, null); end if;   -- ماتشات عامة بس
end $$;


