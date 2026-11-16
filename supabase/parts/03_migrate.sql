-- الجزء 3 من 7 — شغّل الأجزاء بالترتيب (اتعمل من migrate_all.sql بـ tool/split_sql.py)
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

-- حقائق كل لاعب في تشكيلات اليوزر في الجولات اللي خلصت
drop function if exists public.fn_user_pick_facts(uuid);
create or replace function public.fn_user_pick_facts(u uuid)
returns table(round_end timestamptz, player_id uuid, status text, is_captain boolean, is_vice boolean,
              saved_at timestamptz, deadline timestamptz, base int, played boolean, goals int,
              round_max int, owner_pct numeric, chip text)
language sql stable security definer set search_path = public as $$
  with mine as (
    select rp.round_end, rp.player_id, rp.status, rp.is_captain, rp.is_vice, rp.saved_at
    from public.round_picks rp where rp.user_id = u and rp.round_end <= now()
  ), rounds as (
    select distinct mine.round_end from mine
  ), ev as (
    select rounds.round_end, x.player_id, sum(x.points)::int as pts, sum(x.goals)::int as goals
    from rounds
    cross join lateral public.fn_pmp(public.fn_round_from(rounds.round_end), rounds.round_end) x
    group by rounds.round_end, x.player_id
  ), mx as (
    select ev.round_end, max(ev.pts) as mx from ev group by ev.round_end
  ), own as (
    select rp.round_end, rp.player_id, count(*)::numeric as n from public.round_picks rp
    where rp.round_end in (select rounds.round_end from rounds) group by rp.round_end, rp.player_id
  ), tot as (
    select rp.round_end, count(distinct rp.user_id)::numeric as n from public.round_picks rp
    where rp.round_end in (select rounds.round_end from rounds) group by rp.round_end
  )
  select mine.round_end, mine.player_id, mine.status, mine.is_captain, mine.is_vice, mine.saved_at,
    public.fn_round_deadline(mine.round_end), coalesce(ev.pts, 0), ev.player_id is not null, coalesce(ev.goals, 0),
    coalesce(mx.mx, 0), round(coalesce(own.n, 0) * 100 / greatest(tot.n, 1), 1),
    (select c.chip from public.chip_uses c where c.user_id = u and c.week_cutoff = mine.round_end)
  from mine
  left join ev on ev.round_end = mine.round_end and ev.player_id = mine.player_id
  left join mx on mx.round_end = mine.round_end
  left join own on own.round_end = mine.round_end and own.player_id = mine.player_id
  left join tot on tot.round_end = mine.round_end;
$$;

-- الشارات الشخصية لليوزر (بتتحسب لما يبقى عنده نشاط جديد)
create or replace function public.fn_award_badges(u uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v int;
begin
  drop table if exists _pf;
  create temp table _pf as select * from public.fn_user_pick_facts(u);

  perform public.fn_set_badge(u, 'hawk_eye',
    (select count(distinct round_end) from _pf where is_captain and goals >= 3)::int);
  perform public.fn_set_badge(u, 'right_captain',
    (select count(distinct round_end) from _pf where is_captain and base > 0 and base >= round_max)::int);
  perform public.fn_set_badge(u, 'differential',
    (select count(distinct round_end) from _pf where status = 'starting' and base >= 10 and owner_pct < 10)::int);
  perform public.fn_set_badge(u, 'golden_five', (select count(*) from (
    select round_end from _pf where status = 'starting' group by round_end
    having count(*) filter (where base > 0) = 5) x)::int);
  perform public.fn_set_badge(u, 'bench_betrayal', (select count(*) from (
    select round_end from _pf group by round_end
    having coalesce(max(chip), '') <> 'bench_boost'
       and coalesce(sum(base) filter (where status = 'bench'), 0) > coalesce(sum(base) filter (where status = 'starting'), 0)) x)::int);
  perform public.fn_set_badge(u, 'saviour', (select count(*) from (
    select round_end from _pf group by round_end
    having not bool_or(is_captain and played)
       and coalesce(max(base) filter (where is_vice), 0) >= 8) x)::int);
  perform public.fn_set_badge(u, 'early_bird', (select count(*) from (
    select round_end from _pf group by round_end
    having max(saved_at) <= max(deadline) - interval '24 hours') x)::int);
  perform public.fn_set_badge(u, 'last_second', (select count(*) from (
    select round_end from _pf group by round_end
    having max(saved_at) > max(deadline) - interval '1 minute') x)::int);
  drop table if exists _pf;

  -- مش بيفوّت: أطول سلسلة جولات ورا بعض فيها تشكيلة
  select coalesce(max(n), 0) into v from (
    select count(*) as n from (
      select wk - (row_number() over (order by wk)) * interval '7 days' as grp
      from (select distinct rp.round_end as wk from public.round_picks rp
            where rp.user_id = u and rp.round_end <= now()) w
    ) g group by grp) s;
  perform public.fn_set_badge(u, 'streak', v);

  -- المدمن: كام جولة لعبتها
  perform public.fn_set_badge(u, 'addict', (select count(distinct rp.round_end) from public.round_picks rp
    where rp.user_id = u and rp.round_end <= now())::int);

  perform public.fn_set_badge(u, 'oracle', (select count(*) from public.predictions pr
    join public.matches m on m.id = pr.match_id
    where pr.user_id = u and m.is_challenge and m.status = 'finished'
      and pr.score_a - pr.score_b = m.score_a - m.score_b)::int);
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
  -- رقم قياسي: كام مرة نقطك في جولة كسرت أعلى رقم في تاريخ التطبيق وقتها
  perform public.fn_set_badge(u, 'record', (select count(*) from public.user_round_points a
    where a.user_id = u and a.round_end <= now() and a.points > 0
      and a.points > coalesce((select max(b.points) from public.user_round_points b
                               where b.round_end < a.round_end), 0))::int);
end $$;

-- شارات الجولة (بتتحسب مرة واحدة لما الجولة تخلص السبت ٤ العصر)
create or replace function public.fn_round_badges(p_cutoff timestamptz)
returns void language plpgsql security definer set search_path = public as $$
declare f timestamptz := public.fn_round_from(p_cutoff); r record; best int;
begin
  drop table if exists _rt;
  create temp table _rt as
    select urp.user_id, urp.points as pts from public.user_round_points urp where urp.round_end = p_cutoff;

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
    with b as (select urp.user_id, sum(urp.points) as s from public.user_round_points urp
               where urp.round_end <= f group by urp.user_id),
         a as (select urp.user_id, sum(urp.points) as s from public.user_round_points urp
               where urp.round_end <= p_cutoff group by urp.user_id),
         rb as (select user_id, rank() over (order by s desc) as rk from b),
         ra as (select user_id, rank() over (order by s desc) as rk from a)
    select ra.user_id from ra join rb on rb.user_id = ra.user_id where rb.rk - ra.rk >= 20 loop
    perform public.fn_bump_badge(r.user_id, 'rocket');
  end loop;

  -- ملك اليوم: الأعلى في نقط أساسييه (والكابتن ×٢) في كل يوم من أيام الجولة
  for r in
    with d as (select rp.user_id, (m.date_time at time zone 'Africa/Cairo')::date as dy,
                      sum(x.points * case when rp.is_captain then 2 else 1 end) as s
               from public.round_picks rp
               join public.fn_pmp(f, p_cutoff) x on x.player_id = rp.player_id
               join public.matches m on m.id = x.match_id
               where rp.round_end = p_cutoff and rp.status = 'starting'
               group by 1, 2),
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
    with c as (select rp.player_id, count(*) as n from public.round_picks rp
               where rp.is_captain and rp.round_end = p_cutoff group by rp.player_id)
    select pl.user_id from c join public.players pl on pl.id = c.player_id
    where pl.user_id is not null and c.n = (select max(n) from c) loop
    perform public.fn_bump_badge(r.user_id, 'people_captain');
  end loop;
  for r in
    select pl.user_id from (
      select rp.player_id from public.round_picks rp
      where rp.is_captain and rp.round_end = p_cutoff
      group by rp.player_id having count(*) >= 30) c
    join public.players pl on pl.id = c.player_id
    where pl.user_id is not null
      and coalesce((select sum(x.points) from public.fn_pmp(f, p_cutoff, c.player_id) x), 0) <= 0 loop
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
  update public.profiles set badges_dirty = false where badges_dirty and role = 'organizer';
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

-- اللاعيبة الموثّقين: "انت كابتن عند N واحد" أول ما ديدلاين الجولة يعدّي (مرة واحدة)
create or replace function public.fn_notify_captains()
returns void language plpgsql security definer set search_path = public as $$
declare r timestamptz := public.fn_open_round() - interval '7 days';   -- آخر جولة ديدلاينها عدّى
begin
  if now() < public.fn_round_deadline(r) then return; end if;
  insert into public.app_jobs (key) values ('captains:' || to_char(r at time zone 'UTC', 'YYYYMMDDHH24'))
  on conflict do nothing;
  if not found then return; end if;
  insert into public.notifications (title, body, kind, user_id)
  select '🔥 انت كابتن عند ' || count(*) || ' واحد', 'في الجولة اللي جاية — ورّيهم', 'status', pl.user_id
  from public.round_picks p join public.players pl on pl.id = p.player_id
  where p.round_end = r and p.is_captain and pl.user_id is not null
  group by pl.user_id;
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
  perform public.fn_review_tick();
  perform public.fn_snapshot_ranks();
  perform public.fn_refresh_round_stats(public.fn_week_cutoff(now()));   -- إحصائيات السوق

  c := public.fn_week_cutoff(now());
  cp := c - interval '7 days';                         -- آخر جولة قفلت
  k := 'round:' || to_char(cp at time zone 'UTC', 'YYYYMMDDHH24');
  if now() > cp then
    insert into public.app_jobs (key) values (k) on conflict do nothing;
    if found then
      if now() < cp + interval '16 hours' then
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
-- رابط فانكشن الإشعارات بيختلف من مشروع للتاني — بيتحط مرة واحدة يدوي في كل مشروع
-- (من غيره الإشعارات بتتسجّل في التطبيق بس ومفيش push):
--   insert into private.settings (key, value)
--   values ('push_url', 'https://<project-ref>.supabase.co/functions/v1/push') on conflict (key) do nothing;
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
  -- (الماتشات والأحداث والتصويتات والإشعارات بقت بإشارات Broadcast — قسم 24)
  foreach t in array array['venues', 'bookings', 'user_badges', 'venue_reviews'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 21) MATCH INTEGRITY — المنظّمين + تأكيد الطرفين + الاعتماد       ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- الفكرة: اللي بيدخّل الأهداف ميستفيدش منها، وورقة الماتش بتتأكد من لاعيبة الفريقين.
--   ١) المنظّم = يوزر الأدمن وافق على طلبه. بيدير ماتشاته بس، ومينفعش يختار منها في الفانتازي.
--   ٢) الماتش يخلص → pending: اللاعيبة الموثّقين في التشكيلة يأكدوا ✅ أو يعترضوا ❌.
--   ٣) مفيش اعتراض خلال ١٢ ساعة → معتمد لوحده. لو فيه علامة غرابة → لازم تأكيد صريح من الفريقين.
--   ٤) اعتراض → disputed → الأدمن يحكم (اعتماد / إلغاء الماتش / إعادة المراجعة).
--   نقط الماتش بتبان لايف "مبدئية"، والإجمالي والترتيب بيحسبوا المعتمد بس (fn_user_points).

create table if not exists public.match_reviews (
  match_id   uuid references public.matches(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  team       text not null,
  ok         boolean not null,
  note       text check (note is null or length(note) <= 300),
  created_at timestamptz not null default now(),
  primary key (match_id, user_id)
);
alter table public.match_reviews enable row level security;
drop policy if exists "match reviews read" on public.match_reviews;
create policy "match reviews read" on public.match_reviews for select to authenticated using (
  user_id = auth.uid() or public.is_manager()
  or exists (select 1 from public.matches m where m.id = match_id and m.organizer_id = auth.uid())
);
-- مفيش كتابة مباشرة: بدالة review_match بس

-- منطقة فريق بالاسم
create or replace function public.fn_team_zone(p_name text)
returns int language sql stable security definer set search_path = public as $$
  select zone_id from public.teams where lower(trim(name)) = lower(trim(p_name));
$$;

create or replace function public.fn_ensure_team(p_name text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not public.is_manager() then return; end if;   -- الأدمن أو السيرفر بس
  insert into public.teams (name)
  select trim(p_name)
  where not exists (select 1 from public.teams where lower(trim(name)) = lower(trim(p_name)));
end $$;

-- المنظّم: الماتش لازم يتعمل قبل ديدلاين جولته (عشان اليوزرز يختاروا وهما عارفين مين هيلعب)
create or replace function public.fn_check_round_open(p_when timestamptz)
returns void language plpgsql stable as $$
begin
  if now() >= public.fn_round_deadline(public.fn_week_cutoff(p_when)) then
    raise exception 'ديدلاين الجولة دي عدّى (السبت ٣ العصر) — حط الماتش في الجولة الجاية';
  end if;
end $$;

-- المنظّم: الفريقين لازم يكونوا بتوعه
create or replace function public.fn_check_my_teams(p_teams text[])
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if (select count(*) from public.teams t
      where t.owner_id = auth.uid() and lower(trim(t.name)) in (lower(trim(p_teams[1])), lower(trim(p_teams[2])))) < 2 then
    raise exception 'الفريقين لازم يكونوا من فرقك — ضيفهم من "فرقي"';
  end if;
end $$;

create or replace function public.fn_reset_reviews(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  -- بتتنادى من السيرفر، أو في طلب الأدمن/مدير الماتش بس
  if auth.uid() is not null and not (public.is_manager()
      or exists (select 1 from public.matches where id = p_match and organizer_id = auth.uid())) then
    raise exception 'مش مسموح';
  end if;
  delete from public.match_reviews where match_id = p_match;
end $$;

-- حماية الماتش من التطبيق: المنظّم ميقدرش يلعب في حالة الاعتماد ولا الأعمدة بتاعة السيرفر
create or replace function public.trg_matches_guard()
returns trigger language plpgsql as $$
declare client boolean := current_user in ('authenticated', 'anon') and not public.is_manager();
begin
  -- للكل (حتى الأدمن): مفيش ماتشات في الفاصل بين الجولتين
  if (tg_op = 'INSERT' or new.date_time is distinct from old.date_time) and public.fn_in_round_gap(new.date_time) then
    raise exception 'مفيش ماتشات السبت من ٨ الصبح لـ ٤ العصر (بين الجولتين)';
  end if;
  if tg_op = 'INSERT' then
    if client then
      new.organizer_id := auth.uid();
      new.status := 'upcoming';
      new.score_a := null;
      new.score_b := null;
      new.review_status := 'open';
      new.review_due := null;
      new.flags := '{}';
      new.is_challenge := false;
      new.motm_player_id := null;
      new.motm_done := false;
      new.captains_notified := false;
      new.tiebreak_done := false;
      if new.date_time < now() + public.fn_create_lead() and not public.fn_test_mode() then
        raise exception 'ميعاد الماتش لازم يكون بعد ساعتين على الأقل (عشان الناس تلحق تختار لاعيبته)';
      end if;
      if coalesce(array_length(new.teams, 1), 0) <> 2 or new.teams[1] = new.teams[2] then
        raise exception 'لازم فريقين مختلفين';
      end if;
      perform public.fn_check_my_teams(new.teams);
      perform public.fn_check_round_open(new.date_time);
    end if;
    new.zone_id := coalesce(public.fn_team_zone(new.teams[1]), new.zone_id);
    return new;
  end if;

  if client then
    new.organizer_id := old.organizer_id;
    new.review_status := old.review_status;
    new.review_due := old.review_due;
    new.flags := old.flags;
    new.is_challenge := old.is_challenge;
    new.motm_player_id := old.motm_player_id;
    new.motm_done := old.motm_done;
    new.captains_notified := old.captains_notified;
    new.tiebreak_done := old.tiebreak_done;
    if (new.date_time, new.teams) is distinct from (old.date_time, old.teams) then
      if now() >= old.date_time - public.fn_lock_lead() and not public.fn_test_mode() then
        raise exception 'مينفعش تغيّر الميعاد أو الفرق بعد قفل التشكيلات';
      end if;
      if new.date_time < now() + public.fn_create_lead() and not public.fn_test_mode() then
        raise exception 'ميعاد الماتش لازم يكون بعد ساعتين على الأقل (عشان الناس تلحق تختار لاعيبته)';
      end if;
      if new.teams is distinct from old.teams then perform public.fn_check_my_teams(new.teams); end if;
      if new.date_time is distinct from old.date_time then perform public.fn_check_round_open(new.date_time); end if;
    end if;
    if old.status = 'finished' and new.status <> 'finished' then
      raise exception 'الماتش خلص — لو فيه غلط كلّم الإدارة';
    end if;
    if new.status = 'finished' and old.status <> 'finished' and now() < old.date_time and not public.fn_test_mode() then
      raise exception 'الماتش لسه مبدأش';
    end if;
    -- تعديل النتيجة بعد النهاية = علامة غرابة + التأكيدات تتلغي
    if old.status = 'finished' and (new.score_a, new.score_b) is distinct from (old.score_a, old.score_b) then
      new.flags := array(select distinct unnest(old.flags || array['late_edit']));
      new.review_due := now() + public.fn_review_window();
      perform public.fn_reset_reviews(old.id);
    end if;
  end if;

  if new.teams is distinct from old.teams then
    new.zone_id := coalesce(public.fn_team_zone(new.teams[1]), new.zone_id);
  end if;
  -- النتيجة = الأهداف المسجّلة (+ الجول العكسي للفريق التاني) — محدش بيكتبها بإيده
  if new.status = 'finished' or old.score_a is not null
     or exists (select 1 from public.events e where e.match_id = new.id and e.type in ('goal', 'ownGoal')) then
    select s.a, s.b into new.score_a, new.score_b from public.fn_match_score(new.id) s;
  end if;

  -- الأدمن رجّع الماتش لـ "لسه" → المراجعة تبدأ من الأول
  if old.status = 'finished' and new.status <> 'finished' then
    new.review_status := 'open';
    new.review_due := null;
    new.flags := '{}';
    perform public.fn_reset_reviews(old.id);
  end if;
  return new;
end $$;
drop trigger if exists matches_guard on public.matches;
create trigger matches_guard before insert or update on public.matches
for each row execute function public.trg_matches_guard();

-- حماية اللاعيبة: المنظّم ميقدرش يغيّر الإحصائيات ولا التوثيق
create or replace function public.trg_players_guard()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated', 'anon') and not public.is_manager() then
    if tg_op = 'INSERT' then
      new.created_by := auth.uid();
      new.user_id := null;
      new.total_points := 0;
      new.form := 0;
      new.goals := 0;
      new.assists := 0;
      new.clean_sheets := 0;
      new.yellow_cards := 0;
    else
      new.created_by := old.created_by;
      new.user_id := old.user_id;
      new.total_points := old.total_points;
      new.form := old.form;
      new.goals := old.goals;
      new.assists := old.assists;
      new.clean_sheets := old.clean_sheets;
      new.yellow_cards := old.yellow_cards;
    end if;
    if not exists (select 1 from public.teams t
                   where lower(trim(t.name)) = lower(trim(new.team)) and t.owner_id = auth.uid()) then
      raise exception 'الفريق ده مش بتاعك — ضيفه من "فرقي" الأول';
    end if;
  elsif trim(coalesce(new.team, '')) <> '' then
    perform public.fn_ensure_team(new.team);          -- الأدمن: أي اسم جديد بيبقى فريق (من غير منطقة)
  end if;
  new.zone_id := public.fn_team_zone(new.team);
  return new;
end $$;
drop trigger if exists players_guard on public.players;
create trigger players_guard before insert or update on public.players
for each row execute function public.trg_players_guard();

-- علامات الغرابة (مش ممنوعات — بس الماتش ميتعتمدش بالسكوت):
--   score_mismatch  الأهداف المسجّلة مش نفس النتيجة
--   big_margin      فرق ١٠ أهداف أو أكتر
--   organizer_stats المنظّم نفسه عمل ٣ أهداف/أسيست أو أكتر
--   new_organizer   المنظّم عنده أقل من ٥ ماتشات معتمدة
--   late_edit       (بيتحط لوحده) أحداث أو نتيجة اتعدّلت بعد النهاية
create or replace function public.fn_match_flags(p_match uuid)
returns text[] language sql stable security definer set search_path = public as $$
  with m as (select * from public.matches where id = p_match),
  g as (
    select
      count(*) filter (where (e.type = 'goal' and pl.team = m.teams[1]) or (e.type = 'ownGoal' and pl.team = m.teams[2])) as ga,
      count(*) filter (where (e.type = 'goal' and pl.team = m.teams[2]) or (e.type = 'ownGoal' and pl.team = m.teams[1])) as gb,
      count(*) filter (where e.type in ('goal', 'assist') and pl.user_id = m.organizer_id) as org
    from m
    left join public.events e on e.match_id = m.id
    left join public.players pl on pl.id = e.player_id
  )
  select array_remove(array[
    case when g.ga <> coalesce(m.score_a, 0) or g.gb <> coalesce(m.score_b, 0) then 'score_mismatch' end,
    case when abs(coalesce(m.score_a, 0) - coalesce(m.score_b, 0)) >= 10 then 'big_margin' end,
    case when g.org >= 3 then 'organizer_stats' end,
    case when (select count(*) from public.matches x
               where x.organizer_id = m.organizer_id and x.review_status = 'approved') < 5 then 'new_organizer' end
  ], null)
  from m, g;
$$;

-- الماتش خلص → إشعار بالنتيجة + (لو منظّم) مراجعة ١٢ ساعة + طلب تأكيد من اللاعيبة الموثّقين
create or replace function public.fn_start_review(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  select * into m from public.matches where id = p_match;
  perform public.fn_notify_match(p_match, 'انتهى الماتش 🏁',
    m.teams[1] || ' ' || m.score_a || ' - ' || m.score_b || ' ' || m.teams[2], 'match');
  -- ماتشات الأدمن معتمدة على طول
  if m.organizer_id is null or exists (select 1 from public.profiles where id = m.organizer_id and role = 'manager') then
    update public.matches set review_status = 'approved', review_due = null where id = p_match;
    return;
  end if;
  update public.matches
  set review_status = 'pending', review_due = now() + public.fn_review_window(),
      flags = array(select distinct unnest(m.flags || public.fn_match_flags(p_match)))
  where id = p_match;
  perform public.fn_ask_reviewers(p_match);
end $$;

create or replace function public.fn_ask_reviewers(p_match uuid)
returns void language sql security definer set search_path = public as $$
  insert into public.notifications (title, body, kind, user_id, match_id)
  select distinct on (pl.user_id) '📋 أكّد ورقة الماتش',
         m.teams[1] || ' ' || m.score_a || ' - ' || m.score_b || ' ' || m.teams[2] || ' — النتيجة والأهداف صح؟',
         'review', pl.user_id, m.id
  from public.matches m
  join public.lineups l on l.match_id = m.id
  join public.players pl on pl.id = l.player_id
  where m.id = p_match and pl.user_id is not null and pl.user_id is distinct from m.organizer_id;
$$;

create or replace function public.trg_match_review()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'finished' and old.status is distinct from 'finished' then
    perform public.fn_start_review(new.id);
  end if;
  return null;
end $$;
drop trigger if exists match_review on public.matches;
create trigger match_review after update on public.matches
for each row execute function public.trg_match_review();

-- المنظّم عدّل أحداث بعد النهاية → علامة late_edit + التأكيدات تتلغي + الـ ١٢ ساعة تبدأ من الأول
create or replace function public.fn_mark_late_edit(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not (public.is_manager()
      or exists (select 1 from public.matches where id = p_match and organizer_id = auth.uid())) then
    raise exception 'مش مسموح';
  end if;
  update public.matches
  set flags = array(select distinct unnest(flags || array['late_edit'])), review_due = now() + public.fn_review_window()
  where id = p_match and status = 'finished' and review_status = 'pending';
  if found then perform public.fn_reset_reviews(p_match); end if;
end $$;

create or replace function public.trg_events_late()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated', 'anon') and not public.is_manager() then
    perform public.fn_mark_late_edit(coalesce(new.match_id, old.match_id));
  end if;
  return null;
end $$;
drop trigger if exists events_late on public.events;
create trigger events_late after insert or update or delete on public.events
for each row execute function public.trg_events_late();

-- الفريق اللي أنا لاعب موثّق فيه في الماتش ده (null = مش من حقي أراجع)
create or replace function public.fn_reviewer_team(p_match uuid, p_user uuid)
returns text language sql stable security definer set search_path = public as $$
  select pl.team from public.lineups l
  join public.players pl on pl.id = l.player_id
  join public.matches m on m.id = l.match_id
  where l.match_id = p_match and pl.user_id = p_user and m.organizer_id is distinct from p_user
    and not exists (select 1 from public.profiles pr where pr.id = p_user and pr.role = 'organizer')
  limit 1;
$$;

-- ✅ / ❌ على ورقة الماتش
create or replace function public.review_match(p_match uuid, p_ok boolean, p_note text default null)
returns text language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); m public.matches; t text; n text := nullif(trim(p_note), '');
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  perform public.fn_assert_active();
  select * into m from public.matches where id = p_match for update;
  if not found or m.review_status <> 'pending' then raise exception 'الماتش مش مستني تأكيد'; end if;
  t := public.fn_reviewer_team(p_match, u);
  if t is null then raise exception 'لازم تكون لاعب موثّق في تشكيلة الماتش'; end if;
  if not p_ok and n is null then raise exception 'اكتب إيه الغلط'; end if;

  insert into public.match_reviews (match_id, user_id, team, ok, note)
  values (p_match, u, t, p_ok, left(n, 300))
  on conflict (match_id, user_id) do update set ok = excluded.ok, note = excluded.note, created_at = now();

  if not p_ok then
    update public.matches set review_status = 'disputed' where id = p_match;
    insert into public.notifications (title, body, kind, user_id, match_id)
    select '⚠️ اعتراض على ماتش', m.teams[1] || ' ضد ' || m.teams[2] || ' — ' || left(n, 120), 'review', p.id, p_match
    from public.profiles p where p.role = 'manager' or p.id = m.organizer_id;
    return 'disputed';
  end if;

  -- الفريقين أكّدوا → معتمد على طول
  if exists (select 1 from public.match_reviews r where r.match_id = p_match and r.ok and r.team = m.teams[1])
     and exists (select 1 from public.match_reviews r where r.match_id = p_match and r.ok and r.team = m.teams[2]) then
    update public.matches set review_status = 'approved', review_due = null where id = p_match;
    return 'approved';
  end if;
  return 'ok';
end $$;
grant execute on function public.review_match(uuid, boolean, text) to authenticated;

-- الماتشات اللي مستنية تأكيدي
create or replace function public.my_pending_reviews()
returns table(id uuid, teams text[], date_time timestamptz, score_a int, score_b int, flags text[], my_team text)
language sql stable security definer set search_path = public as $$
  select m.id, m.teams, m.date_time, m.score_a, m.score_b, m.flags, public.fn_reviewer_team(m.id, auth.uid())
  from public.matches m
  where m.review_status = 'pending'
    and public.fn_reviewer_team(m.id, auth.uid()) is not null
    and not exists (select 1 from public.match_reviews r where r.match_id = m.id and r.user_id = auth.uid())
  order by m.date_time desc;
$$;
grant execute on function public.my_pending_reviews() to authenticated;

-- كل دورة: المعتمد بالسكوت (من غير علامات)، والمعلّم عليه اللي عدّى وقته → تنبيه للأدمن مرة واحدة
create or replace function public.fn_review_tick()
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  update public.matches set review_status = 'approved', review_due = null
  where review_status = 'pending' and review_due <= now() and cardinality(flags) = 0;
  for r in select id, teams from public.matches
           where review_status = 'pending' and review_due <= now() and cardinality(flags) > 0 loop
    insert into public.app_jobs (key) values ('review-nudge:' || r.id) on conflict do nothing;
    if found then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🔎 ماتش محتاج مراجعتك', r.teams[1] || ' ضد ' || r.teams[2] || ' — فيه علامات ومحدش أكّد', 'review', p.id, r.id
      from public.profiles p where p.role = 'manager';
    end if;
  end loop;
end $$;

-- (أدمن) الحكم: approve = اعتماد · void = إلغاء الماتش (الأحداث تتمسح والنقط تروح) · reopen = مراجعة من الأول
create or replace function public.resolve_match(p_match uuid, p_action text)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
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

-- (أدمن) طابور المراجعة: الاعتراضات الأول، وبعدين المعلّم عليه
create or replace function public.admin_review_queue()
returns table(id uuid, teams text[], date_time timestamptz, score_a int, score_b int, review_status text,
              review_due timestamptz, flags text[], organizer_name text, reviews jsonb)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query
  select m.id, m.teams, m.date_time, m.score_a, m.score_b, m.review_status, m.review_due, m.flags, o.name,
    coalesce((select jsonb_agg(jsonb_build_object('name', p.name, 'team', r.team, 'ok', r.ok, 'note', r.note)
                               order by r.created_at)
              from public.match_reviews r join public.profiles p on p.id = r.user_id
              where r.match_id = m.id), '[]'::jsonb)
  from public.matches m
  left join public.profiles o on o.id = m.organizer_id
  where m.review_status = 'disputed' or (m.review_status = 'pending' and cardinality(m.flags) > 0)
  order by (m.review_status = 'disputed') desc, m.date_time desc
  limit 100;
end $$;
grant execute on function public.admin_review_queue() to authenticated;

-- (منظّم/أدمن) إشعار "التشكيلة نزلت" — المنظّم مرة واحدة لكل ماتش
create or replace function public.notify_lineup(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  if not (public.is_manager() or public.fn_organizes(p_match)) then raise exception 'مش ماتشك'; end if;
  select * into m from public.matches where id = p_match;
  if not public.is_manager() then
    insert into public.app_jobs (key) values ('lineup:' || p_match) on conflict do nothing;
    if not found then raise exception 'الإشعار اتبعت قبل كده'; end if;
  end if;
  perform public.fn_notify_match(p_match, 'تشكيلة نزلت ⚽',
    m.teams[1] || ' ضد ' || m.teams[2] || ' — اختار تشكيلتك قبل الديدلاين', 'lineup');
end $$;
grant execute on function public.notify_lineup(uuid) to authenticated;

-- ── طلبات "عايز أنظّم ماتشات" ──
create table if not exists public.organizer_requests (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  note        text check (note is null or length(note) <= 300),
  status      text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz
);
create unique index if not exists organizer_requests_one_pending on public.organizer_requests(user_id)
  where status = 'pending';
alter table public.organizer_requests enable row level security;
drop policy if exists "organizer requests read" on public.organizer_requests;
create policy "organizer requests read" on public.organizer_requests for select to authenticated
  using (user_id = auth.uid() or public.is_manager());
drop policy if exists "organizer requests insert" on public.organizer_requests;
create policy "organizer requests insert" on public.organizer_requests for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending'
              and exists (select 1 from public.profiles p
                          where p.id = auth.uid() and p.role = 'user' and p.zone_id is not null));

create or replace function public.trg_organizer_request_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare un text;
begin
  select name into un from public.profiles where id = new.user_id;
  insert into public.notifications (title, body, kind, user_id)
  select '🧑‍⚖️ طلب مدير منطقة', coalesce(un, 'يوزر') || coalesce(' — ' || left(new.note, 100), ''), 'status', p.id
  from public.profiles p where p.role = 'manager';
  return new;
end $$;
drop trigger if exists organizer_request_notify on public.organizer_requests;
create trigger organizer_request_notify after insert on public.organizer_requests
for each row execute function public.trg_organizer_request_notify();

create or replace function public.pending_organizer_requests()
returns table(id uuid, user_id uuid, user_name text, phone text, note text, player_name text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query
  select r.id, r.user_id, p.name, p.phone, r.note,
         (select pl.name from public.players pl where pl.user_id = r.user_id), r.created_at
  from public.organizer_requests r join public.profiles p on p.id = r.user_id
  where r.status = 'pending' order by r.created_at;
end $$;
grant execute on function public.pending_organizer_requests() to authenticated;

create or replace function public.review_organizer_request(p_req uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
declare r public.organizer_requests;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  select * into r from public.organizer_requests where id = p_req;
  if not found or r.status <> 'pending' then raise exception 'الطلب مش موجود أو اتراجع'; end if;
  update public.organizer_requests set status = case when p_approve then 'approved' else 'rejected' end,
         reviewed_at = now() where id = p_req;
  perform public.fn_admin_log(case when p_approve then 'approve_manager' else 'reject_manager' end,
                              r.user_id::text, '{}'::jsonb);
  if p_approve then
    if exists (select 1 from public.players where user_id = r.user_id) then
      raise exception 'اليوزر ده موثّق كلاعب — فك التوثيق الأول (المدير مش بيلعب)';
    end if;
    update public.profiles set role = 'organizer' where id = r.user_id and role = 'user';
    perform public.fn_leave_fantasy(r.user_id);
    insert into public.notifications (title, body, kind, user_id)
    values ('✓ بقيت مدير منطقة', 'حسابك بقى حساب إدارة: اعمل فرقك وماتشاتك من "منطقتي"', 'status', r.user_id);
  else
    insert into public.notifications (title, body, kind, user_id)
    values ('طلب التنظيم اترفض', 'تقدر تكلّم الإدارة وتقدّم تاني', 'status', r.user_id);
  end if;
end $$;
grant execute on function public.review_organizer_request(uuid, boolean) to authenticated;

-- الإجمالي بقى بيحسب المعتمد بس → نحدّث إجمالي الكل مرة (خفيفة دلوقتي — لو اليوزرز بقوا بالآلاف شيلها بعد أول تشغيل)
update public.profiles set total_points = public.fn_user_points(id) where id is not null;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 22) ZONES & TEAMS — المناطق والفرق بأصحابها                     ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- اليوزر ليه منطقة: بيشوف ماتشاتها وإشعاراتها ونجم وتشكيلة الجولة بتاعتها، وميقدرش يعمل تشكيلة بره منطقته.
-- المنظّم بيعمل فرق في منطقته، والماتش لازم يكون بين فريقين من فرقه (منطقة الماتش = منطقة فرقه).
-- الماتشات القديمة/بتاعة الأدمن من غير منطقة = عامة لكل المناطق.

alter table public.teams enable row level security;
drop policy if exists "teams read" on public.teams;
create policy "teams read" on public.teams for select to authenticated using (true);
drop policy if exists "teams organizer insert" on public.teams;
create policy "teams organizer insert" on public.teams for insert to authenticated
  with check (public.is_organizer());
drop policy if exists "teams manager write" on public.teams;
create policy "teams manager write" on public.teams for update to authenticated
  using (public.is_manager()) with check (public.is_manager());
-- الحذف: الأدمن، أو الصاحب لو الفريق لسه ملوش لاعيبة ولا ماتشات
drop policy if exists "teams delete" on public.teams;
create policy "teams delete" on public.teams for delete to authenticated using (
  public.is_manager()
  or (owner_id = auth.uid()
      and not exists (select 1 from public.players pl where lower(trim(pl.team)) = lower(trim(teams.name)))
      and not exists (select 1 from public.matches m
                      where lower(trim(teams.name)) in (lower(trim(m.teams[1])), lower(trim(m.teams[2])))))
);

-- المنظّم: الفريق بيتسجّل باسمه وفي منطقته. الاسم مبيتغيّرش (هو المفتاح في اللاعيبة والماتشات).
create or replace function public.trg_teams_guard()
returns trigger language plpgsql as $$
declare z int;
begin
  new.name := trim(new.name);
  if tg_op = 'UPDATE' and new.name <> old.name then
    raise exception 'مينفعش تغيّر اسم الفريق — اعمل فريق جديد';
  end if;
  if current_user in ('authenticated', 'anon') and not public.is_manager() then
    if tg_op = 'INSERT' then
      select zone_id into z from public.profiles where id = auth.uid();
      if z is null then raise exception 'اختار منطقتك الأول'; end if;
      if (select count(*) from public.teams where owner_id = auth.uid()) >= 30 then
        raise exception 'آخرك ٣٠ فريق';
      end if;
      new.owner_id := auth.uid();
      new.zone_id := z;
    else
      new.owner_id := old.owner_id;
      new.zone_id := old.zone_id;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists teams_guard on public.teams;
create trigger teams_guard before insert or update on public.teams
for each row execute function public.trg_teams_guard();

-- الأدمن غيّر منطقة فريق → لاعيبته وماتشاته الجاية تتنقل معاه
create or replace function public.trg_teams_zone()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.zone_id is distinct from old.zone_id then
    update public.players set zone_id = new.zone_id where lower(trim(team)) = lower(trim(new.name));
    update public.matches set zone_id = new.zone_id
    where lower(trim(teams[1])) = lower(trim(new.name)) and status = 'upcoming';
  end if;
  return null;
end $$;
drop trigger if exists teams_zone on public.teams;
create trigger teams_zone after update on public.teams
for each row execute function public.trg_teams_zone();

-- ماتش جديد / ميعاده اتغيّر → إشعار لأهل منطقته (بدل ما التطبيق يبعته)
create or replace function public.trg_match_announce()
returns trigger language plpgsql security definer set search_path = public as $$
declare t text := to_char(new.date_time at time zone 'Africa/Cairo', 'DD/MM · HH12:MI');
begin
  if tg_op = 'INSERT' then
    perform public.fn_notify_match(new.id, 'ماتش جديد ⚽', new.teams[1] || ' ضد ' || new.teams[2] || ' · ' || t, 'match');
  elsif new.status = 'upcoming' and (new.date_time, new.teams) is distinct from (old.date_time, old.teams) then
    perform public.fn_notify_match(new.id, 'تعديل في ماتش 📝',
      new.teams[1] || ' ضد ' || new.teams[2] || ' · الميعاد الجديد ' || t, 'match');
  end if;
  return null;
end $$;
drop trigger if exists match_announce on public.matches;
create trigger match_announce after insert or update on public.matches
for each row execute function public.trg_match_announce();


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 23) ROLES — الأدمن ومديرين المناطق + سجل العمليات               ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- manager (الأدمن): كل الصلاحيات — بيتضاف من Supabase بس.
-- organizer (مدير منطقة): فرقه وماتشاته ولاعيبة فرقه في منطقته بس. حساب شغل:
--   مبيعملش تشكيلة ولا كروت ولا توقّع ولا تصويت ولا تقييم ولا دوريات، ومش بيظهر في الترتيب.
-- user: اللعب العادي.

-- سجل عمليات الأدمنز (مين عمل إيه وإمتى)
create table if not exists public.admin_log (
  id         bigserial primary key,
  admin_id   uuid references public.profiles(id) on delete set null,
  action     text not null,
  target     text,
  detail     jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists admin_log_created on public.admin_log(created_at desc);
alter table public.admin_log enable row level security;   -- مفيش سياسات: القراية بـ admin_log_list بس

create or replace function public.fn_admin_log(p_action text, p_target text, p_detail jsonb)
returns void language sql security definer set search_path = public as $$
  insert into public.admin_log (admin_id, action, target, detail) values (auth.uid(), p_action, p_target, p_detail);
$$;

create or replace function public.admin_log_list(p_limit int default 100)
returns table(id bigint, admin_name text, action text, target text, detail jsonb, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query
  select l.id, coalesce(p.name, '—'), l.action, l.target, l.detail, l.created_at
  from public.admin_log l left join public.profiles p on p.id = l.admin_id
  order by l.created_at desc limit least(greatest(p_limit, 1), 300);
end $$;
grant execute on function public.admin_log_list(int) to authenticated;

-- لما يوزر يبقى مدير منطقة: يسيب الدوريات وتشكيلاته الجاية
create or replace function public.fn_leave_fantasy(p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from public.round_picks where user_id = p_user and round_end > now();
  delete from public.user_round_points where user_id = p_user and round_end > now();
  delete from public.league_members where user_id = p_user;
end $$;

-- (أدمن) أرقام سريعة للوحة: يوزرز · أدمنز · مديرين · لاعيبة · ماتشات جاية وخلصت
drop function if exists public.admin_counts();
create or replace function public.admin_counts()
returns table(users bigint, admins bigint, managers bigint, players bigint, upcoming bigint, finished bigint)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query select
    (select count(*) from public.profiles where role = 'user'),
    (select count(*) from public.profiles where role = 'manager'),
    (select count(*) from public.profiles where role = 'organizer'),
    (select count(*) from public.players),
    (select count(*) from public.matches where status = 'upcoming'),
    (select count(*) from public.matches where status = 'finished');
end $$;
grant execute on function public.admin_counts() to authenticated;

-- (أدمن) تذكير بتشكيلة الجولة: إشعار واحد لأهل منطقة الماتش (مش إشعار لكل يوزر)
create or replace function public.remind_round(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r timestamptz;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  select public.fn_week_cutoff(date_time) into r from public.matches where id = p_match;
  if r is null then raise exception 'الماتش مش موجود'; end if;
  if now() >= public.fn_round_deadline(r) then raise exception 'ديدلاين الجولة عدّى'; end if;
  perform public.fn_notify_match(p_match, 'متنساش تشكيلتك ⏰',
    'تشكيلات الجولة بتقفل السبت ٣ العصر — ٧ لاعيبة + كابتن وبديل', 'lineup');
end $$;
grant execute on function public.remind_round(uuid) to authenticated;

-- (أدمن) نقل يوزر/مدير لمنطقة تانية (فرق المدير بتفضل في منطقتها — انقلها من "الفرق" لو محتاج)
create or replace function public.admin_set_zone(p_user uuid, p_zone int)
returns void language plpgsql security definer set search_path = public as $$
declare old int;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  if not exists (select 1 from public.zones where id = p_zone) then raise exception 'المنطقة مش موجودة'; end if;
  select zone_id into old from public.profiles where id = p_user;
  update public.profiles set zone_id = p_zone, zone_changed_at = now() where id = p_user;
  perform public.fn_admin_log('set_zone', p_user::text, jsonb_build_object('from', old, 'to', p_zone));
end $$;
grant execute on function public.admin_set_zone(uuid, int) to authenticated;

-- (أدمن) تغيير منطقة فريق بيتسجّل
create or replace function public.trg_teams_log()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.zone_id is distinct from old.zone_id and public.is_manager() then
    perform public.fn_admin_log('team_zone', new.name, jsonb_build_object('from', old.zone_id, 'to', new.zone_id));
  end if;
  return null;
end $$;
drop trigger if exists teams_log on public.teams;
create trigger teams_log after update on public.teams
for each row execute function public.trg_teams_log();

-- رقم موبايل واحد لحساب واحد (عشان المدير ميعملش حساب تاني يلعب بيه من غير ما نعرف)
do $$ begin
  create unique index if not exists profiles_phone_unique on public.profiles (trim(phone))
    where phone is not null and trim(phone) <> '';
exception when unique_violation then
  raise notice 'فيه أرقام موبايل متكررة — صلّحها وشغّل الملف تاني عشان القاعدة تتفعّل';
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 24) LIVE & CACHE — لايف خفيف + إحصائيات محسوبة مسبقًا           ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- بدل ما كل موبايل يسمع لجدول كامل (السيرفر بيفحص الصلاحيات لكل موبايل مع كل تغيير):
-- السيرفر بيبعت إشارة صغيرة {kind} (Broadcast) لقناة واحدة: zone:ID (أهل المنطقة) · all (الكل) · user:ID (يوزر)،
-- والأبلكيشن بيحمّل اللي يهمه بعد وقت عشوائي صغير (عشان الأجهزة متضربش السيرفر مع بعض).

create or replace function public.fn_zone_topic(p_zone int)
returns text language sql immutable as $$ select coalesce('zone:' || p_zone, 'all'); $$;

create or replace function public.fn_live(p_kind text, p_topic text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform realtime.send(jsonb_build_object('kind', p_kind), 'change', p_topic, false);
exception when others then
  null;   -- اللايف عمره ما يوقّف الكتابة (لو Broadcast مش متاح)
end $$;

create or replace function public.trg_live_events()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_live('events', public.fn_zone_topic(
    (select zone_id from public.matches where id = coalesce(new.match_id, old.match_id))));
  return null;
end $$;
drop trigger if exists live_events on public.events;
create trigger live_events after insert or update or delete on public.events
for each row execute function public.trg_live_events();

create or replace function public.trg_live_matches()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_live('matches', public.fn_zone_topic(coalesce(new.zone_id, old.zone_id)));
  return null;
end $$;
drop trigger if exists live_matches on public.matches;
create trigger live_matches after insert or update or delete on public.matches
for each row execute function public.trg_live_matches();

create or replace function public.trg_live_polls()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_live('polls', public.fn_zone_topic(new.zone_id));
  return null;
end $$;
drop trigger if exists live_polls on public.polls;
create trigger live_polls after insert or update on public.polls
for each row execute function public.trg_live_polls();

-- إشعار جديد → إشارة لجمهوره بس (العدّاد بيتحدّث من غير ما كل الأجهزة تسمع لجدول الإشعارات)
create or replace function public.trg_live_notifications()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_live('notify', case new.audience
    when 'user' then 'user:' || new.user_id
    when 'zone' then public.fn_zone_topic(new.zone_id)
    when 'match' then public.fn_zone_topic((select zone_id from public.matches where id = new.match_id))
    else 'all' end);
  return null;
end $$;
drop trigger if exists live_notifications on public.notifications;
create trigger live_notifications after insert on public.notifications
for each row execute function public.trg_live_notifications();

-- الجداول دي مبقتش بتتسمع مباشرة (postgres_changes) — نشيلها من الـ publication عشان السيرفر ميفكّش تغييراتها
do $$
declare t text;
begin
  foreach t in array array['events', 'matches', 'players', 'lineups', 'polls', 'poll_votes', 'picks',
                           'round_picks', 'notifications'] loop
    begin
      execute format('alter publication supabase_realtime drop table public.%I', t);
    exception when others then null;
    end;
  end loop;
end $$;

-- إحصائيات اللاعيبة في الجولة (الامتلاك والنقط والانتقالات) محسوبة مسبقًا كل ١٠ دقايق،
-- بدل ما كل موبايل يفتح السوق يحسبها من كل التشكيلات.
create table if not exists public.player_round_stats (
  round_end     timestamptz not null,
  player_id     uuid not null references public.players(id) on delete cascade,
  points        bigint not null default 0,
  owners        bigint not null default 0,
  ownership     numeric not null default 0,
  transfers_in  bigint not null default 0,
  transfers_out bigint not null default 0,
  managers      bigint not null default 0,
  primary key (round_end, player_id)
);
alter table public.player_round_stats enable row level security;
drop policy if exists "round stats read" on public.player_round_stats;
create policy "round stats read" on public.player_round_stats for select to authenticated using (true);

create or replace function public.fn_refresh_round_stats(p_round timestamptz)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from public.player_round_stats where round_end = p_round;
  insert into public.player_round_stats
    (round_end, player_id, points, owners, ownership, transfers_in, transfers_out, managers)
  select p_round, s.id, s.points, s.owners, s.ownership, s.transfers_in, s.transfers_out, s.managers
  from public.player_window_stats(public.fn_round_from(p_round), p_round) s
  where s.owners > 0 or s.points <> 0 or s.transfers_out > 0;
  delete from public.player_round_stats where round_end < p_round - interval '60 days';
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 25) SECURITY — قفل الدوال الداخلية + الحظر + حدود المحتوى        ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- ── الحظر ──
-- اليوزر المحظور (is_active = false) يقدر يتفرّج بس: ميكتبش أي حاجة ومش بيظهر في الترتيب.
create or replace function public.fn_me_active()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select is_active from public.profiles where id = auth.uid()), true);
$$;

create or replace function public.fn_assert_active()
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if not public.fn_me_active() then raise exception 'حسابك موقوف — كلّم الإدارة'; end if;
end $$;

-- سياسات "restrictive" بتتضاف فوق كل السياسات: المحظور ميضيفش ولا يعدّل ولا يمسح
do $$
declare t text;
begin
  foreach t in array array['poll_votes', 'player_ratings', 'venue_reviews', 'bookings', 'leagues',
                           'league_members', 'predictions', 'player_claims', 'organizer_requests', 'venues',
                           'match_follows', 'teams', 'players', 'matches', 'events', 'lineups', 'profiles'] loop
    execute format('drop policy if exists "active only insert" on public.%I', t);
    execute format('create policy "active only insert" on public.%I as restrictive for insert to authenticated
                    with check (public.fn_me_active())', t);
    execute format('drop policy if exists "active only update" on public.%I', t);
    execute format('create policy "active only update" on public.%I as restrictive for update to authenticated
                    using (public.fn_me_active())', t);
    execute format('drop policy if exists "active only delete" on public.%I', t);
    execute format('create policy "active only delete" on public.%I as restrictive for delete to authenticated
                    using (public.fn_me_active())', t);
  end loop;
end $$;

-- (أدمن) حظر / فك حظر (الأدمن مبيتحظرش)
create or replace function public.set_user_active(p_user uuid, p_active boolean)
returns void language plpgsql security definer set search_path = public as $$
declare t public.profiles;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  select * into t from public.profiles where id = p_user;
  if not found then raise exception 'اليوزر مش موجود'; end if;
  if t.role = 'manager' then raise exception 'مينفعش تحظر أدمن'; end if;
  update public.profiles set is_active = p_active where id = p_user;
  perform public.fn_admin_log(case when p_active then 'unban' else 'ban' end, p_user::text,
                              jsonb_build_object('name', t.name));
  if not p_active then
    insert into public.notifications (title, body, kind, user_id)
    values ('حسابك اتوقف', 'لو شايف إن ده غلط كلّم الإدارة', 'status', p_user);
  end if;
end $$;

-- الحساب الجديد → البروفايل بيتعمل في السيرفر (مش من التطبيق): بيشتغل حتى مع تأكيد الإيميل،
-- ومفيش حساب من غير بروفايل لو النت فصل. البيانات جاية من signUp(data: {name, phone, zone_id, ref_code}).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare m jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb); z int; ref uuid;
begin
  begin
    z := nullif(m->>'zone_id', '')::int;
  exception when others then z := null;
  end;
  if z is not null and not exists (select 1 from public.zones where id = z) then z := null; end if;
  select id into ref from public.profiles where ref_code = upper(trim(coalesce(m->>'ref_code', '')));
  insert into public.profiles (id, name, email, phone, zone_id, zone_changed_at, referred_by)
  values (new.id, left(trim(coalesce(m->>'name', '')), 40), coalesce(new.email, ''),
          nullif(trim(coalesce(m->>'phone', '')), ''), z, case when z is null then null else now() end, ref)
  on conflict (id) do nothing;
  if ref is not null then update public.profiles set badges_dirty = true where id = ref; end if;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- رقم الموبايل متسجّل؟ (للتسجيل — من غير ما نكشف الإيميل)
create or replace function public.phone_taken(p text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where trim(phone) = trim(p));
$$;

-- ── حذف الحساب من جوه التطبيق (Apple و Google بيطلبوه) ──
-- بيمسح الحساب وكل بياناته (البروفايل وكل حاجة مربوطة بيه بتتمسح أو بتتفك: on delete cascade / set null).
-- الصور بيمسحها التطبيق الأول من الـ Storage (الـ SQL ممنوع يمسح ملفات مباشرة).
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
declare u uuid := auth.uid();
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  if exists (select 1 from public.profiles where id = u and role = 'manager')
     and (select count(*) from public.profiles where role = 'manager') <= 1 then
    raise exception 'انت آخر أدمن — ضيف أدمن تاني الأول';
  end if;
  delete from auth.users where id = u;
end $$;
grant execute on function public.delete_my_account() to authenticated;

-- ── حدود المحتوى (للصفوف الجديدة بس — NOT VALID مش بتكسر القديم) ──
do $$ begin
  alter table public.profiles add constraint profiles_name_len check (length(name) <= 40) not valid;
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.profiles add constraint profiles_phone_len check (phone is null or length(phone) <= 20) not valid;
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.players add constraint players_name_len check (length(name) between 1 and 40) not valid;
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.leagues add constraint leagues_name_len check (length(name) between 1 and 40) not valid;
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.venues add constraint venues_name_len check (length(name) between 1 and 60) not valid;
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.bookings add constraint bookings_note_len check (note is null or length(note) <= 200) not valid;
exception when duplicate_object then null; end $$;

-- ── قفل الدوال ──
-- Supabase بيخلّي أي دالة في public قابلة للنداء من التطبيق. بنقفل الكل، ونفتح بس:
--   ١) الدوال اللي التطبيق بيناديها (القايمة تحت)
--   ٢) الدوال العادية (مش security definer) — بتشتغل بصلاحيات اللي ناداها فمبتكسرش حاجة،
--      والسياسات والـ triggers محتاجاها.
do $$
declare r record;
begin
  for r in select p.oid::regprocedure as f, p.prosecdef as definer
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public'
             and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e') loop
    execute format('revoke execute on function %s from public, anon, authenticated', r.f);
    if not r.definer then
      execute format('grant execute on function %s to authenticated', r.f);
    end if;
  end loop;
end $$;

-- الدوال الجديدة مقفولة من الأول
do $$ begin
  alter default privileges for role postgres in schema public revoke execute on functions from public, anon, authenticated;
exception when others then null; end $$;

-- دوال السيرفر اللي السياسات والـ triggers بتناديها (آمنة لو اتنادت مباشرة)
grant execute on function public.is_manager() to authenticated;
grant execute on function public.is_organizer() to authenticated;
grant execute on function public.fn_my_league_count() to authenticated;
grant execute on function public.fn_is_zone_manager() to authenticated;
grant execute on function public.fn_me_active() to authenticated;
grant execute on function public.fn_organizes(uuid) to authenticated;
grant execute on function public.fn_event_ok(uuid, uuid) to authenticated;
grant execute on function public.fn_rating_open(uuid) to authenticated;
grant execute on function public.fn_team_zone(text) to authenticated;
grant execute on function public.fn_check_my_teams(text[]) to authenticated;
grant execute on function public.fn_reset_reviews(uuid) to authenticated;
grant execute on function public.fn_mark_late_edit(uuid) to authenticated;
grant execute on function public.fn_ensure_team(text) to authenticated;
grant execute on function public.set_user_active(uuid, boolean) to authenticated;
grant execute on function public.phone_taken(text) to anon, authenticated;
grant execute on function public.delete_my_account() to authenticated;

-- دوال التطبيق
grant execute on function public.email_for_phone(text) to service_role;   -- للسيرفر بس (قسم 44)
grant execute on function public.player_week_points(int) to authenticated;
grant execute on function public.player_gw_stats(int) to authenticated;
grant execute on function public.player_history(uuid) to authenticated;
grant execute on function public.player_points_between(timestamptz, timestamptz, int) to authenticated;
grant execute on function public.player_window_stats(timestamptz, timestamptz) to authenticated;
grant execute on function public.set_my_zone(int) to authenticated;
grant execute on function public.my_profile() to authenticated;
grant execute on function public.admin_users(text, text, int) to authenticated;
grant execute on function public.set_user_role(uuid, text) to authenticated;
grant execute on function public.apply_referral(text) to authenticated;
grant execute on function public.venue_slots(uuid, date, date) to authenticated;
grant execute on function public.booking_list(text) to authenticated;
grant execute on function public.set_booking_status(uuid, text) to authenticated;
grant execute on function public.venue_ratings() to authenticated;
grant execute on function public.venue_review_list(uuid) to authenticated;
grant execute on function public.chip_status(timestamptz) to authenticated;
grant execute on function public.set_challenge(uuid) to authenticated;
grant execute on function public.challenge_summary(uuid) to authenticated;
grant execute on function public.match_rating_summary(uuid) to authenticated;
grant execute on function public.review_claim(uuid, boolean) to authenticated;
grant execute on function public.unlink_player(uuid) to authenticated;
grant execute on function public.pending_claims() to authenticated;
grant execute on function public.player_fan_stats(uuid, timestamptz, timestamptz) to authenticated;
grant execute on function public.save_round_picks(timestamptz, jsonb) to authenticated;
grant execute on function public.activate_chip(timestamptz, text) to authenticated;
grant execute on function public.join_league(text) to authenticated;
grant execute on function public.my_leagues() to authenticated;
grant execute on function public.admin_leagues() to authenticated;
grant execute on function public.create_global_league(text) to authenticated;
grant execute on function public.league_standings(uuid, int, int) to authenticated;
grant execute on function public.my_global_rank() to authenticated;
grant execute on function public.create_season_award(text) to authenticated;
grant execute on function public.review_match(uuid, boolean, text) to authenticated;
grant execute on function public.my_pending_reviews() to authenticated;
grant execute on function public.resolve_match(uuid, text) to authenticated;
grant execute on function public.admin_review_queue() to authenticated;
grant execute on function public.notify_lineup(uuid) to authenticated;
grant execute on function public.pending_organizer_requests() to authenticated;
grant execute on function public.review_organizer_request(uuid, boolean) to authenticated;
grant execute on function public.admin_log_list(int) to authenticated;
grant execute on function public.admin_counts() to authenticated;
grant execute on function public.remind_round(uuid) to authenticated;
grant execute on function public.admin_set_zone(uuid, int) to authenticated;


