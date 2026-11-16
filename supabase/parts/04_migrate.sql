-- الجزء 4 من 7 — شغّل الأجزاء بالترتيب (اتعمل من migrate_all.sql بـ tool/split_sql.py)
-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 26) TEAM OF THE WEEK — تشكيلة الجولة بموافقة الأدمن لكل منطقة    ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- مش لايف: الجولة تخلص (السبت ٤ العصر) → النظام بيقترح أعلى ٥ نقط لكل منطقة (ولو فيه تعادل على آخر مكان
-- اليوزرز بيصوّتوا ٢٠ ساعة) → الأدمن يراجع ويعتمد → التشكيلة تنزل لأهل المنطقة مرة واحدة + إشعار.
-- zone_id = 0 → الماتشات العامة (من غير منطقة).

create table if not exists public.team_of_week (
  round_end   timestamptz not null,
  zone_id     int not null default 0,
  players     jsonb not null,            -- الخمسة (الأعلى نقط الأول) — صورة ثابتة وقت الاعتماد
  approved_by uuid references public.profiles(id) on delete set null,
  approved_at timestamptz not null default now(),
  primary key (round_end, zone_id)
);
alter table public.team_of_week enable row level security;
drop policy if exists "totw read" on public.team_of_week;
create policy "totw read" on public.team_of_week for select to authenticated using (true);
-- مفيش كتابة مباشرة: publish_totw بس

-- نقط لاعيبة منطقة في جولة (0 = لاعيبة الماتشات العامة بس)
create or replace function public.fn_zone_round_points(p_round timestamptz, p_zone int)
returns table(id uuid, name text, team text, "position" text, points bigint, image_url text, verified boolean)
language sql stable security definer set search_path = public as $$
  select t.* from public.player_points_between(public.fn_round_from(p_round), p_round, nullif(p_zone, 0)) t
  join public.players pl on pl.id = t.id
  where t.points > 0 and (p_zone <> 0 or pl.zone_id is null);
$$;

-- (أدمن) اقتراحات جولة: لكل منطقة فيها ماتشات — المرشّحين (أعلى ١٢)، حالة تصويت التعادل، واتنشرت ولا لأ
create or replace function public.admin_totw_candidates(p_round timestamptz)
returns table(zone_id int, zone_label text, candidates jsonb, slots int, tie_open boolean,
              tie_winners uuid[], published boolean)
language plpgsql stable security definer set search_path = public as $$
declare z record; pl public.polls;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  for z in select distinct coalesce(m.zone_id, 0) as zid from public.matches m
           where m.date_time > public.fn_round_from(p_round) and m.date_time <= p_round
             and m.review_status <> 'void' order by 1 loop
    zone_id := z.zid;
    zone_label := coalesce((select zz.name || ' · ' || zz.governorate from public.zones zz where zz.id = z.zid), 'عام');
    candidates := coalesce((select jsonb_agg(to_jsonb(c) order by c.points desc, c.name)
                            from ((select * from public.fn_zone_round_points(p_round, z.zid) g
                                   where g.position = 'GK' order by g.points desc, g.name limit 3)
                                  union all
                                  (select * from public.fn_zone_round_points(p_round, z.zid) o
                                   where o.position <> 'GK' order by o.points desc, o.name limit 10)) c), '[]'::jsonb);
    select * into pl from public.polls p
    where p.kind = 'totw_tie' and p.window_end = p_round and p.zone_id is not distinct from nullif(z.zid, 0)
    order by p.created_at desc limit 1;
    tie_open := pl.id is not null and pl.active;
    slots := coalesce(pl.slots, 0);
    tie_winners := case when pl.id is null or pl.active then null else
      (select array_agg(w.player_id) from (
         select o.player_id from public.poll_options o left join public.poll_votes v on v.option_id = o.id
         where o.poll_id = pl.id group by o.id, o.player_id
         order by count(v.user_id) desc, min(o.id::text) limit pl.slots) w) end;
    published := exists (select 1 from public.team_of_week t where t.round_end = p_round and t.zone_id = z.zid);
    return next;
  end loop;
end $$;

-- (أدمن) اعتماد ونشر تشكيلة منطقة (٥ لاعيبة من اللي جابوا نقط في الجولة)
create or replace function public.publish_totw(p_round timestamptz, p_zone int, p_players uuid[])
returns void language plpgsql security definer set search_path = public as $$
declare snap jsonb; n int; first_time boolean;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  if now() <= p_round and not public.fn_test_mode() then raise exception 'الجولة لسه مخلصتش'; end if;
  if cardinality(p_players) <> 5 or (select count(distinct x) from unnest(p_players) x) <> 5 then
    raise exception 'التشكيلة ٥ لاعيبة مختلفين';
  end if;
  select jsonb_agg(to_jsonb(t) order by t.points desc, t.name), count(*) into snap, n
  from public.fn_zone_round_points(p_round, p_zone) t where t.id = any(p_players);
  if n <> 5 then raise exception 'فيه لاعب ملوش نقط في الجولة دي في المنطقة دي'; end if;
  if (select count(*) from jsonb_array_elements(snap) e where e->>'position' = 'GK') <> 1 then
    raise exception 'التشكيلة لازم حارس واحد + ٤ لاعيبة';
  end if;
  first_time := not exists (select 1 from public.team_of_week where round_end = p_round and zone_id = p_zone);
  insert into public.team_of_week (round_end, zone_id, players, approved_by, approved_at)
  values (p_round, p_zone, snap, auth.uid(), now())
  on conflict (round_end, zone_id) do update
    set players = excluded.players, approved_by = excluded.approved_by, approved_at = excluded.approved_at;
  if first_time then
    insert into public.notifications (title, body, kind, audience, zone_id)
    values ('⭐ تشكيلة الجولة نزلت', 'نجم الجولة: ' || (snap->0->>'name') || ' · ' || (snap->0->>'points') || ' نقطة',
            'match', case when p_zone = 0 then 'all' else 'zone' end, nullif(p_zone, 0));
  end if;
  perform public.fn_admin_log('publish_totw', p_zone::text,
    jsonb_build_object('round', p_round, 'zone', p_zone, 'star', snap->0->>'name'));
end $$;

grant execute on function public.admin_totw_candidates(timestamptz) to authenticated;
grant execute on function public.round_player_points(timestamptz, uuid[]) to authenticated;
grant execute on function public.publish_totw(timestamptz, int, uuid[]) to authenticated;


-- ═══ 27. (اتشال: طلبات «ماتش بعد الديدلاين» — مبقاش فيه ديدلاين للجولة من قسم 51-ج) ═══

-- ═══ 28. كل يوزر في منطقته بس ═══
-- تشكيلة الجولة (ونجمها) لأهل المنطقة بس — يوزر بدر مايشوفش تشكيلة الشروق.
drop policy if exists "totw read" on public.team_of_week;
create policy "totw read" on public.team_of_week for select to authenticated using (
  public.is_manager()
  or zone_id = (select p.zone_id from public.profiles p where p.id = auth.uid())
);

-- حالة لاعب (جاهز · مصاب · مشكوك · موقوف) → إشعار لأهل منطقته بس (مكانش بيتبعت غير من التطبيق وللكل)
create or replace function public.trg_player_status_notify()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.zone_id is null
     or (new.availability, coalesce(new.news, '')) is not distinct from (old.availability, coalesce(old.news, '')) then
    return null;
  end if;
  insert into public.notifications (title, body, kind, audience, zone_id)
  values (case new.availability when 'injured' then 'مصاب' when 'doubtful' then 'مشكوك'
                                when 'suspended' then 'موقوف' else 'جاهز' end || ' — ' || new.name || ' 🩺',
          coalesce(nullif(trim(new.news), ''), new.team), 'status', 'zone', new.zone_id);
  return null;
end $$;
drop trigger if exists player_status_notify on public.players;
create trigger player_status_notify after update of availability, news on public.players
for each row execute function public.trg_player_status_notify();

-- ═══ 29. الماتش لايف: النتيجة من الأهداف · التبديل · الكروت ═══
-- النتيجة = أهداف لاعيبة كل فريق + الجول العكسي من لاعيبة الفريق التاني
create or replace function public.fn_match_score(p_match uuid)
returns table(a int, b int) language sql stable security definer set search_path = public as $$
  select
    (count(*) filter (where (e.type = 'goal' and pl.team = m.teams[1]) or (e.type = 'ownGoal' and pl.team = m.teams[2])))::int,
    (count(*) filter (where (e.type = 'goal' and pl.team = m.teams[2]) or (e.type = 'ownGoal' and pl.team = m.teams[1])))::int
  from public.matches m
  left join public.events e on e.match_id = m.id and e.type in ('goal', 'ownGoal')
  left join public.players pl on pl.id = e.player_id
  where m.id = p_match
  group by m.id, m.teams;
$$;

-- كل جول (أو مسحه) → النتيجة تتحدّث على طول (والكل بيشوفها لايف من غير ما حد يكتبها)
create or replace function public.trg_event_score()
returns trigger language plpgsql security definer set search_path = public as $$
declare mid uuid := coalesce(new.match_id, old.match_id);
begin
  if coalesce(new.type, old.type) not in ('goal', 'ownGoal') and coalesce(old.type, '') not in ('goal', 'ownGoal') then
    return null;
  end if;
  update public.matches m set score_a = s.a, score_b = s.b
  from public.fn_match_score(mid) s
  where m.id = mid and (m.score_a, m.score_b) is distinct from (s.a, s.b);
  return null;
end $$;
drop trigger if exists event_score on public.events;
create trigger event_score after insert or update or delete on public.events
for each row execute function public.trg_event_score();

-- التبديل: اللي نزل كان احتياطي واللي طلع كان في الملعب، والاتنين من نفس الفريق
create or replace function public.trg_event_sub_check()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.type <> 'sub' then
    new.other_player_id := null;
    return new;
  end if;
  if new.other_player_id is null or new.other_player_id = new.player_id then
    raise exception 'التبديل محتاج اللي طلع واللي نزل';
  end if;
  if not exists (select 1 from public.lineups l where l.match_id = new.match_id and l.player_id = new.player_id
                 and l.status = 'bench') then
    raise exception 'اللي نازل لازم يكون من الاحتياطي';
  end if;
  if exists (select 1 from public.events e where e.match_id = new.match_id and e.type = 'sub'
             and e.player_id = new.player_id and e.id <> new.id) then
    raise exception 'اللاعب ده نزل خلاص';
  end if;
  if (select team from public.players where id = new.player_id)
     is distinct from (select team from public.players where id = new.other_player_id) then
    raise exception 'التبديل لازم من نفس الفريق';
  end if;
  return new;
end $$;
-- (مش على تغيير other_player_id: حذف اللاعب اللي طلع بيفضّيه من غير ما يكسر الحذف)
drop trigger if exists event_sub_check on public.events;
create trigger event_sub_check before insert or update of type, player_id on public.events
for each row execute function public.trg_event_sub_check();

grant execute on function public.fn_match_score(uuid) to authenticated;

-- ═══ 30. وضع التجربة: جولة واحدة + موسم تجربة ═══
-- (بيشتغل بس لو fn_test_mode() = true — ومع الإطلاق: امسح "موسم التجربة" وشغّل reset_data.sql)
do $$
declare r timestamptz;
begin
  if not public.fn_test_mode() then return; end if;
  r := public.fn_week_cutoff(now());

  -- موسم بيغطّي جولة التجربة عشان الكروت تشتغل
  if not exists (select 1 from public.seasons s where r - interval '7 days' >= s.starts_at and r - interval '7 days' < s.ends_at) then
    insert into public.seasons (name, starts_at, mid_at, ends_at)
    values ('موسم التجربة', timestamptz '2000-01-01', timestamptz '2099-12-31', timestamptz '2100-12-31');
  end if;

  -- آخر تشكيلة لكل يوزر بتتنقل لجولة التجربة، والجولات القديمة بتتشال (عشان النقط متتحسبش مرتين)
  if exists (select 1 from public.round_picks where round_end <> r) then
    insert into public.round_picks (user_id, round_end, player_id, status, is_captain, is_vice, saved_at)
    select rp.user_id, r, rp.player_id, rp.status, rp.is_captain, rp.is_vice, rp.saved_at
    from public.round_picks rp
    where rp.round_end = (select max(x.round_end) from public.round_picks x where x.user_id = rp.user_id)
      and rp.round_end <> r
      and not exists (select 1 from public.round_picks y where y.user_id = rp.user_id and y.round_end = r);
    delete from public.round_picks where round_end <> r;
    delete from public.user_round_points where round_end <> r;
    delete from public.chip_uses where week_cutoff <> r;
    perform public.fn_recalc_round_players(r, array(select distinct player_id from public.round_picks where round_end = r));
    update public.profiles set total_points = public.fn_user_points(id) where id is not null;
  end if;
end $$;

-- ═══ 31. الإشعار بيفتح صفحته ═══
-- link = الصفحة اللي الإشعار بيوديك ليها لما تدوس عليه (في الأبلكيشن أو من الـ push):
--   match:ID · review:ID · player:ID · challenge · team · totw · awards · pitch · badges · leagues · account · home
--   admin:review · admin:organizers · admin:late · admin:claims
alter table public.notifications add column if not exists link text;

create or replace function public.fn_notification_link(p_kind text, p_title text, p_match uuid)
returns text language sql immutable as $$
  select case
    when p_title like '📋%' and p_match is not null then 'review:' || p_match
    when p_title like '⚠️%' or p_title like '🔎%' then 'admin:review'
    when p_title like '🧑‍⚖️%' then 'admin:organizers'
    when p_title like '⏰ طلب ماتش%' then 'admin:late'
    when p_title like '🪪%' then 'admin:claims'
    when p_kind = 'challenge' then 'challenge'
    when p_title like 'متنساش تشكيلتك%' or p_title like '🔥%' then 'team'
    when p_title like '⭐ تشكيلة الجولة%' or p_title like '⚖️%' then 'totw'
    when p_kind = 'vote' then 'awards'
    when p_kind = 'booking' then 'pitch'
    when p_kind = 'badge' then 'badges'
    when p_title like '🏆 الدوري%' then 'leagues'
    when p_title like '✓ اتوثّق%' then 'account'
    when p_title like '✓ الماتش اتضاف%' or p_title like '✓ بقيت مدير%' then 'home'
    when p_match is not null then 'match:' || p_match
    else null end;
$$;

create or replace function public.trg_notifications_link()
returns trigger language plpgsql as $$
begin
  if new.link is null then new.link := public.fn_notification_link(new.kind, new.title, new.match_id); end if;
  return new;
end $$;
drop trigger if exists notifications_link on public.notifications;
create trigger notifications_link before insert on public.notifications
for each row execute function public.trg_notifications_link();

-- الإشعارات القديمة كمان
update public.notifications set link = public.fn_notification_link(kind, title, match_id) where link is null;

-- حالة لاعب (جاهز · مصاب …) → بتفتح صفحة اللاعب
create or replace function public.trg_player_status_notify()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.zone_id is null
     or (new.availability, coalesce(new.news, '')) is not distinct from (old.availability, coalesce(old.news, '')) then
    return null;
  end if;
  insert into public.notifications (title, body, kind, audience, zone_id, link)
  values (case new.availability when 'injured' then 'مصاب' when 'doubtful' then 'مشكوك'
                                when 'suspended' then 'موقوف' else 'جاهز' end || ' — ' || new.name || ' 🩺',
          coalesce(nullif(trim(new.news), ''), new.team), 'status', 'zone', new.zone_id, 'player:' || new.id);
  return null;
end $$;

-- ═══ 32. حذف بالجملة · تشكيلات الناس · اللاعب عمل إيه ═══

-- حذف لاعيبة (واحد أو كتير): الأدمن أي لاعب · مدير المنطقة لاعيبة فرقه اللي لسه ملهمش أحداث بس
-- (اللاعب اللي لعب نقطه في تشكيلات الناس — حذفه من الأدمن بس). بيرجّع كام اتحذف.
create or replace function public.delete_players(p_ids uuid[])
returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  perform public.fn_assert_active();
  if public.is_manager() then
    delete from public.players where id = any(p_ids);
    get diagnostics n = row_count;
    perform public.fn_admin_log('delete_players', n::text, jsonb_build_object('ids', to_jsonb(p_ids)));
    return n;
  end if;
  if not (public.is_organizer() or public.is_captain() or public.is_venue_host()) then raise exception 'مش مسموح'; end if;
  delete from public.players pl
  where pl.id = any(p_ids)
    and exists (select 1 from public.teams t where lower(trim(t.name)) = lower(trim(pl.team)) and t.owner_id = auth.uid())
    and not exists (select 1 from public.events e where e.player_id = pl.id);
  get diagnostics n = row_count;
  return n;
end $$;

-- (أدمن) مديرين منطقة → يوزرز عاديين (بالجملة)
create or replace function public.admin_demote_organizers(p_ids uuid[])
returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  update public.profiles set role = 'user' where id = any(p_ids) and role = 'organizer';
  get diagnostics n = row_count;
  perform public.fn_admin_log('demote_organizers', n::text, jsonb_build_object('ids', to_jsonb(p_ids)));
  return n;
end $$;

-- (أدمن) مسح حسابات خالص (يوزرز أو مديرين — الأدمنز وحسابك مش بيتمسحوا). مفيش رجوع.
create or replace function public.admin_delete_users(p_ids uuid[])
returns int language plpgsql security definer set search_path = public, auth as $$
declare n int;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  perform public.fn_admin_log('delete_users', cardinality(p_ids)::text, jsonb_build_object('ids', to_jsonb(p_ids)));
  delete from auth.users u
  where u.id = any(p_ids) and u.id <> auth.uid()
    and not exists (select 1 from public.profiles p where p.id = u.id and p.role = 'manager');
  get diagnostics n = row_count;
  return n;
end $$;

-- تشكيلات الناس (من الدوري): بتبان بعد الديدلاين — وفي التجربة على طول. ومعاها الكارت.
drop policy if exists "round picks read" on public.round_picks;
create policy "round picks read" on public.round_picks for select to authenticated using (
  user_id = auth.uid() or public.is_manager() or now() >= public.fn_round_deadline(round_end) or public.fn_test_mode()
);
drop policy if exists "chips read" on public.chip_uses;
create policy "chips read" on public.chip_uses for select to authenticated using (
  user_id = auth.uid() or public.is_manager() or now() >= public.fn_round_deadline(week_cutoff) or public.fn_test_mode()
);

-- لاعب عمل إيه في جولة: كل ماتش لعبه (ضد مين · النتيجة · نقطه · التفصيل)
create or replace function public.player_round_matches(p_player uuid, p_round timestamptz)
returns table(match_id uuid, teams text[], score_a int, score_b int, date_time timestamptz, status text,
              points int, items jsonb)
language sql stable security definer set search_path = public as $$
  select m.id, m.teams, m.score_a, m.score_b, m.date_time, m.status,
         coalesce(x.points, 0), coalesce(x.items, '[]'::jsonb)
  from public.matches m
  left join public.fn_pmp(public.fn_round_from(p_round), p_round, p_player) x on x.match_id = m.id
  where m.date_time > public.fn_round_from(p_round) and m.date_time <= p_round and m.review_status <> 'void'
    and (x.match_id is not null
         or exists (select 1 from public.lineups l where l.match_id = m.id and l.player_id = p_player))
  order by m.date_time;
$$;

grant execute on function public.delete_players(uuid[]) to authenticated;
grant execute on function public.admin_demote_organizers(uuid[]) to authenticated;
grant execute on function public.admin_delete_users(uuid[]) to authenticated;
grant execute on function public.player_round_matches(uuid, timestamptz) to authenticated;

-- ═══ 33. خماسي ولا سداسي ═══
-- المدير بيحدد الملعب: ٥ (حارس + ٤) أو ٦ (حارس + ٥). كل فريق في الماتش آخره ٧ (الأساسي + احتياطي اختياري).
alter table public.matches add column if not exists format int not null default 5;
do $$ begin
  alter table public.matches add constraint matches_format check (format in (5, 6));
exception when duplicate_object then null; end $$;

-- السقف في السيرفر (التحقّق الكامل "الأساسي = عدد الملعب بالظبط" في الأبلكيشن قبل الحفظ):
-- الفريق ≤ ٧ · الأساسي ≤ الملعب · حارس أساسي واحد بالكتير
create or replace function public.trg_lineup_caps()
returns trigger language plpgsql security definer set search_path = public as $$
declare f int; t text; n_all int; n_start int; n_gk int;
begin
  select m.format into f from public.matches m where m.id = new.match_id;
  select team into t from public.players where id = new.player_id;
  select count(*), count(*) filter (where l.status = 'starting'),
         count(*) filter (where l.status = 'starting' and pl.position = 'GK')
  into n_all, n_start, n_gk
  from public.lineups l join public.players pl on pl.id = l.player_id
  where l.match_id = new.match_id and pl.team = t;
  if n_all > 7 then raise exception 'الفريق آخره ٧ لاعيبة في الماتش (%)', t; end if;
  if n_start > coalesce(f, 5) then raise exception 'الملعب % — آخرك % أساسيين في %', f, f, t; end if;
  if n_gk > 1 then raise exception 'حارس أساسي واحد بس في %', t; end if;
  return null;
end $$;
drop trigger if exists lineup_caps on public.lineups;
create trigger lineup_caps after insert or update on public.lineups
for each row execute function public.trg_lineup_caps();

-- ═══ 34. حركة الترتيب + "جولتك في ٥ سلايدز" ═══
-- صورة الترتيب العام مرة في أول كل جولة (في التجربة: مرة كل يوم) → أسهم ⬆⬇ في الترتيب + ملخص الجولة.
alter table public.profiles add column if not exists prev_rank int;

create or replace function public.fn_snapshot_ranks()
returns void language plpgsql security definer set search_path = public as $$
declare k text := 'ranks:' || case when public.fn_test_mode()
                                   then to_char(now() at time zone 'Africa/Cairo', 'YYYYMMDD')
                                   else to_char(public.fn_week_cutoff(now()) at time zone 'UTC', 'YYYYMMDDHH24') end;
begin
  insert into public.app_jobs (key) values (k) on conflict do nothing;
  if not found then return; end if;
  update public.profiles p set prev_rank = r.rk
  from (select id, rank() over (order by total_points desc, low_picks desc, avg_own asc) as rk
        from public.profiles where role <> 'organizer' and is_active) r
  where p.id = r.id;
end $$;

-- ملخص جولتي: نقطي · ترتيبي دلوقتي وقبلها · أحسن اختيار · الكابتن عمل إيه · الكارت
create or replace function public.my_round_recap(p_round timestamptz)
returns table(points int, rank_now bigint, prev_rank int, users bigint, best_name text, best_points int,
              captain_name text, captain_points int, scorers int, chip text)
language sql stable security definer set search_path = public as $$
  with pk as (
    select rp.player_id, rp.is_captain, rp.status, pl.name,
           coalesce((select sum(x.points) from public.fn_pmp(public.fn_round_from(p_round), p_round, rp.player_id) x), 0)::int as p
    from public.round_picks rp join public.players pl on pl.id = rp.player_id
    where rp.user_id = auth.uid() and rp.round_end = p_round
  )
  select coalesce((select u.points from public.user_round_points u where u.user_id = auth.uid() and u.round_end = p_round), 0),
         public.my_global_rank(),
         (select pr.prev_rank from public.profiles pr where pr.id = auth.uid()),
         (select count(*) from public.profiles where role <> 'organizer' and is_active),
         (select pk.name from pk order by pk.p desc limit 1),
         (select pk.p from pk order by pk.p desc limit 1),
         (select pk.name from pk where pk.is_captain limit 1),
         (select pk.p from pk where pk.is_captain limit 1),
         (select count(*)::int from pk where pk.p > 0 and pk.status = 'starting'),
         (select c.chip from public.chip_uses c where c.user_id = auth.uid() and c.week_cutoff = p_round);
$$;

grant execute on function public.my_round_recap(timestamptz) to authenticated;

-- ═══ 35. دوري المناطق ═══
-- ترتيب المناطق: مجموع نقط ناسها (المتوسط للمعلومة) — الناس بتحارب عشان منطقتها وبتجيب جيرانها.
create or replace function public.zone_standings()
returns table(rank bigint, zone_id int, label text, users bigint, total bigint, avg_points numeric, mine boolean)
language sql stable security definer set search_path = public as $$
  with z as (
    select p.zone_id, count(*) as users, sum(p.total_points)::bigint as total,
           round(avg(p.total_points), 1) as avg_points
    from public.profiles p
    where p.role <> 'organizer' and p.is_active and p.zone_id is not null
    group by p.zone_id
  )
  select rank() over (order by z.total desc, z.avg_points desc), z.zone_id, zz.name || ' · ' || zz.governorate,
         z.users, z.total, z.avg_points,
         z.zone_id = (select pr.zone_id from public.profiles pr where pr.id = auth.uid())
  from z join public.zones zz on zz.id = z.zone_id
  order by z.total desc, z.avg_points desc
  limit 100;
$$;
grant execute on function public.zone_standings() to authenticated;

-- ═══ 36. البطولات ═══
-- الأدمن أو مدير المنطقة بيعمل بطولة (دوري · مجموعات + خروج مغلوب · خروج مغلوب) → الفرق بتتسجّل →
-- القرعة بتعمل الجدول لوحدها → ماتشات البطولة ماتشات عادية (تشكيلة · أحداث · تأكيد · فانتازي) →
-- الترتيب والشجرة بيتحدّثوا لوحدهم، والفايز بيتنقل للدور اللي بعده → البطل + الجوايز + توقّعات البطل (+١٠).
create table if not exists public.tournaments (
  id           uuid primary key default gen_random_uuid(),
  name         text not null check (char_length(name) between 2 and 60),
  zone_id      int not null references public.zones(id),
  format       text not null check (format in ('league', 'groups', 'knockout')),
  team_count   int not null check (team_count between 3 and 32),
  groups_count int not null default 0 check (groups_count between 0 and 8),
  starts_at    timestamptz not null,
  prize        text check (char_length(prize) <= 120),
  sponsor      text check (char_length(sponsor) <= 60),
  status       text not null default 'registration' check (status in ('registration', 'running', 'finished')),
  champion     text,
  created_by   uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now()
);
create index if not exists tournaments_zone on public.tournaments(zone_id, created_at desc);
alter table public.tournaments enable row level security;
drop policy if exists "tournaments read" on public.tournaments;
create policy "tournaments read" on public.tournaments for select to authenticated using (true);

create table if not exists public.tournament_teams (
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  team          text not null,
  group_label   text,
  status        text not null default 'approved' check (status in ('pending', 'approved', 'rejected')),
  captain_id    uuid references public.profiles(id) on delete set null,
  phone         text check (char_length(phone) <= 20),
  note          text check (char_length(note) <= 200),
  created_at    timestamptz not null default now(),
  primary key (tournament_id, team)
);
alter table public.tournament_teams enable row level security;
drop policy if exists "tournament teams read" on public.tournament_teams;
create policy "tournament teams read" on public.tournament_teams for select to authenticated using (true);

-- شجرة خروج المغلوب: كل دور فيه أماكن (slot) — الفايز في الزوج k بيروح لمكان k في الدور اللي بعده
create table if not exists public.tournament_bracket (
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  round         int not null,
  slot          int not null,
  team          text,
  match_id      uuid references public.matches(id) on delete set null,
  primary key (tournament_id, round, slot)
);
alter table public.tournament_bracket enable row level security;
drop policy if exists "bracket read" on public.tournament_bracket;
create policy "bracket read" on public.tournament_bracket for select to authenticated using (true);

create table if not exists public.tournament_predictions (
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  user_id       uuid not null references public.profiles(id) on delete cascade,
  team          text not null,
  created_at    timestamptz not null default now(),
  primary key (tournament_id, user_id)
);
alter table public.tournament_predictions enable row level security;
drop policy if exists "tournament predictions read" on public.tournament_predictions;
create policy "tournament predictions read" on public.tournament_predictions for select to authenticated using (true);

alter table public.matches add column if not exists tournament_id uuid references public.tournaments(id) on delete set null;
alter table public.matches add column if not exists stage text;        -- مجموعة A · ربع النهائي · النهائي …
alter table public.matches add column if not exists winner text;       -- خروج المغلوب: الفايز (بالنتيجة أو بضربات الجزاء)
create index if not exists matches_tournament on public.matches(tournament_id, date_time);

-- مين يدير البطولة: الأدمن أو اللي عملها
create or replace function public.fn_runs_tournament(p_t uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_manager() or exists (select 1 from public.tournaments where id = p_t and created_by = auth.uid());
$$;

-- اسم الدور من عدد الفرق اللي فيه
create or replace function public.fn_stage_name(p_teams int)
returns text language sql immutable as $$
  select case p_teams when 2 then 'النهائي' when 4 then 'نص النهائي' when 8 then 'ربع النهائي'
                      else 'دور الـ' || p_teams end;
$$;

-- ميعاد ماتش في البطولة (يوم بعد يوم من البداية — والمدير يعدّل الميعاد بعدين). مش في فاصل السبت.
create or replace function public.fn_tournament_slot_time(p_t uuid, p_day int)
returns timestamptz language sql stable security definer set search_path = public as $$
  select case when public.fn_in_round_gap(d) then d + interval '8 hours' else d end
  from (select greatest(t.starts_at, now() + interval '1 hour') + p_day * interval '1 day' as d
        from public.tournaments t where t.id = p_t) x;
$$;

-- ماتش بطولة جديد (باسم منظّم البطولة وفي منطقتها)
create or replace function public.fn_tournament_match(p_t uuid, a text, b text, p_stage text, p_day int)
returns uuid language plpgsql security definer set search_path = public as $$
declare t public.tournaments; mid uuid;
begin
  select * into t from public.tournaments where id = p_t;
  insert into public.matches (teams, date_time, week, organizer_id, tournament_id, stage, zone_id)
  values (array[a, b], public.fn_tournament_slot_time(p_t, p_day), 0,
          case when exists (select 1 from public.profiles where id = t.created_by and role = 'organizer')
               then t.created_by end, p_t, p_stage, t.zone_id)
  returning id into mid;
  return mid;
end $$;

-- كل فريق ضد كل فريق (طريقة الدايرة) — للدوري أو لمجموعة
create or replace function public.fn_round_robin(p_t uuid, p_teams text[], p_stage text, p_day0 int)
returns int language plpgsql security definer set search_path = public as $$
declare arr text[] := p_teams; m int; r int; i int; a text; b text; days int := 0;
begin
  if coalesce(array_length(arr, 1), 0) < 2 then return 0; end if;
  if array_length(arr, 1) % 2 = 1 then arr := arr || array[null::text]; end if;   -- راحة
  m := array_length(arr, 1);
  for r in 0 .. m - 2 loop
    for i in 1 .. m / 2 loop
      a := arr[i]; b := arr[m + 1 - i];
      if a is not null and b is not null then
        perform public.fn_tournament_match(p_t, a, b, p_stage, p_day0 + r);
      end if;
    end loop;
    arr := array[arr[1]] || array[arr[m]] || arr[2 : m - 1];   -- الأول ثابت والباقي بيلف
    days := r + 1;
  end loop;
  return days;
end $$;

-- شجرة خروج المغلوب من قايمة فرق (بالترتيب) — الراحة (bye) للأوائل، وبعدها التقدّم بيكمّل لوحده
create or replace function public.fn_build_bracket(p_t uuid, p_teams text[])
returns void language plpgsql security definer set search_path = public as $$
declare n int := coalesce(array_length(p_teams, 1), 0); size int := 2; k int;
begin
  while size < n loop size := size * 2; end loop;
  delete from public.tournament_bracket where tournament_id = p_t;
  for k in 1 .. size / 2 loop
    insert into public.tournament_bracket (tournament_id, round, slot, team) values
      (p_t, 1, 2 * k - 1, p_teams[k]),
      (p_t, 1, 2 * k, case when size / 2 + k <= n then p_teams[size / 2 + k] end);
  end loop;
  perform public.fn_bracket_progress(p_t);
end $$;

-- التقدّم في الشجرة: كل زوج اتحسم → الفايز للدور اللي بعده · زوج اكتمل → ماتشه بيتعمل · النهائي → البطل
create or replace function public.fn_bracket_progress(p_t uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r int := 1; total int; pairs int; k int; s1 public.tournament_bracket; s2 public.tournament_bracket;
        w text; mid uuid; m public.matches;
begin
  select count(*) into total from public.tournament_bracket where tournament_id = p_t and round = 1;
  if total = 0 then return; end if;
  pairs := total / 2;
  while pairs >= 1 loop
    for k in 1 .. pairs loop
      select * into s1 from public.tournament_bracket where tournament_id = p_t and round = r and slot = 2 * k - 1;
      select * into s2 from public.tournament_bracket where tournament_id = p_t and round = r and slot = 2 * k;
      w := null;
      if r = 1 and s1.team is not null and s2.team is null then
        w := s1.team;                                            -- راحة
      elsif s1.team is not null and s2.team is not null then
        mid := coalesce(s1.match_id, s2.match_id);
        if mid is null then
          mid := public.fn_tournament_match(p_t, s1.team, s2.team, public.fn_stage_name(pairs * 2), r - 1);
          update public.tournament_bracket set match_id = mid
          where tournament_id = p_t and round = r and slot in (2 * k - 1, 2 * k);
        end if;
        select * into m from public.matches where id = mid;
        if m.status = 'finished' and m.review_status <> 'void' then w := m.winner; end if;
      end if;
      if w is not null then
        if pairs = 1 then
          update public.tournaments set champion = w, status = 'finished' where id = p_t and champion is null;
          if found then perform public.fn_tournament_champion(p_t); end if;
        else
          insert into public.tournament_bracket (tournament_id, round, slot, team)
          values (p_t, r + 1, k, w)
          on conflict (tournament_id, round, slot) do update set team = excluded.team
            where public.tournament_bracket.team is distinct from excluded.team and public.tournament_bracket.match_id is null;
        end if;
      end if;
    end loop;
    r := r + 1;
    pairs := pairs / 2;
  end loop;
end $$;

-- ترتيب البطولة (الدوري أو كل مجموعة): ٣ للفوز · ١ للتعادل · فارق الأهداف · الأهداف
create or replace function public.tournament_standings(p_t uuid)
returns table(group_label text, team text, played int, won int, drawn int, lost int, gf int, ga int, gd int, pts int)
language sql stable security definer set search_path = public as $$
  with tt as (
    select tt.team, tt.group_label from public.tournament_teams tt where tt.tournament_id = p_t and tt.status = 'approved'
  ), res as (
    select m.teams[1] as team, m.score_a as f, m.score_b as a from public.matches m
    where m.tournament_id = p_t and m.status = 'finished' and m.review_status <> 'void'
      and not exists (select 1 from public.tournament_bracket b where b.match_id = m.id)
    union all
    select m.teams[2], m.score_b, m.score_a from public.matches m
    where m.tournament_id = p_t and m.status = 'finished' and m.review_status <> 'void'
      and not exists (select 1 from public.tournament_bracket b where b.match_id = m.id)
  )
  select tt.group_label, tt.team, count(res.team)::int,
    count(*) filter (where res.f > res.a)::int, count(*) filter (where res.f = res.a)::int,
    count(*) filter (where res.f < res.a)::int,
    coalesce(sum(res.f), 0)::int, coalesce(sum(res.a), 0)::int, coalesce(sum(res.f - res.a), 0)::int,
    (3 * count(*) filter (where res.f > res.a) + count(*) filter (where res.f = res.a))::int
  from tt left join res on res.team = tt.team
  group by tt.group_label, tt.team
  order by tt.group_label nulls first, 10 desc, 9 desc, 7 desc, tt.team;
$$;

-- البطل اتحدّد → إشعار لأهل المنطقة + بونص اللي توقّعوه (+١٠ في الإجمالي)
create or replace function public.fn_tournament_champion(p_t uuid)
returns void language plpgsql security definer set search_path = public as $$
declare t public.tournaments;
begin
  select * into t from public.tournaments where id = p_t;
  insert into public.notifications (title, body, kind, audience, zone_id, link)
  values ('🏆 بطل ' || t.name || ': ' || t.champion, 'شوف الجوايز والهدافين', 'match', 'zone', t.zone_id, 'tournament:' || p_t);
  insert into public.notifications (title, body, kind, user_id, link)
  select '🔮 توقّعت البطل صح! +١٠', t.name || ' — ' || t.champion, 'challenge', p.user_id, 'tournament:' || p_t
  from public.tournament_predictions p where p.tournament_id = p_t and lower(trim(p.team)) = lower(trim(t.champion));
  update public.profiles set total_points = public.fn_user_points(id)
  where id in (select user_id from public.tournament_predictions where tournament_id = p_t);
end $$;

-- بعد أي ماتش بطولة يخلص: الشجرة تتقدّم · الدوري/المجموعات خلصت؟ (الدوري → البطل)
create or replace function public.fn_tournament_progress(p_t uuid)
returns void language plpgsql security definer set search_path = public as $$
declare t public.tournaments; w text;
begin
  select * into t from public.tournaments where id = p_t;
  if t.status <> 'running' then return; end if;
  perform public.fn_bracket_progress(p_t);
  if t.format = 'league' and not exists (select 1 from public.matches m where m.tournament_id = p_t and m.status <> 'finished') then
    select s.team into w from public.tournament_standings(p_t) s limit 1;
    update public.tournaments set champion = w, status = 'finished' where id = p_t and champion is null;
    if found then perform public.fn_tournament_champion(p_t); end if;
  end if;
end $$;

-- الفايز في خروج المغلوب بيتحسب من النتيجة لوحده (التعادل: المنظّم يختار بضربات الجزاء)
create or replace function public.trg_match_winner()
returns trigger language plpgsql as $$
begin
  if new.tournament_id is not null and new.status = 'finished' and new.winner is null
     and new.score_a is not null and new.score_b is not null and new.score_a <> new.score_b then
    new.winner := case when new.score_a > new.score_b then new.teams[1] else new.teams[2] end;
  end if;
  return new;
end $$;
drop trigger if exists zz_match_winner on public.matches;   -- zz = بعد ما النتيجة تتحسب من الأهداف
create trigger zz_match_winner before update on public.matches
for each row execute function public.trg_match_winner();

create or replace function public.trg_match_tournament()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.tournament_id is not null
     and ((new.status = 'finished' and old.status is distinct from 'finished') or new.winner is distinct from old.winner
          or new.review_status is distinct from old.review_status) then
    perform public.fn_tournament_progress(new.tournament_id);
  end if;
  return null;
end $$;
drop trigger if exists match_tournament on public.matches;
create trigger match_tournament after update on public.matches
for each row execute function public.trg_match_tournament();

-- ── الدوال اللي التطبيق بيناديها ──

-- عمل بطولة: مدير المنطقة في منطقته · الأدمن في أي منطقة
create or replace function public.create_tournament(p_name text, p_format text, p_team_count int, p_groups int,
                                                    p_starts timestamptz, p_prize text default null,
                                                    p_sponsor text default null, p_zone int default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare z int; tid uuid;
begin
  perform public.fn_assert_active();
  if public.is_manager() then
    z := coalesce(p_zone, (select zone_id from public.profiles where id = auth.uid()));
  elsif public.is_organizer() then
    z := (select zone_id from public.profiles where id = auth.uid());
  else
    raise exception 'البطولات للمديرين والأدمن';
  end if;
  if z is null then raise exception 'حدد المنطقة'; end if;
  if p_format = 'groups' and (p_groups < 2 or p_groups * 2 > p_team_count) then
    raise exception 'المجموعات: من ٢ لحد نص عدد الفرق';
  end if;
  insert into public.tournaments (name, zone_id, format, team_count, groups_count, starts_at, prize, sponsor, created_by)
  values (trim(p_name), z, p_format, p_team_count, case when p_format = 'groups' then p_groups else 0 end, p_starts,
          nullif(trim(p_prize), ''), nullif(trim(p_sponsor), ''), auth.uid())
  returning id into tid;
  insert into public.notifications (title, body, kind, audience, zone_id, link)
  values ('🏆 بطولة جديدة: ' || trim(p_name), 'التسجيل مفتوح — سجّل فريقك' || coalesce(' · الجايزة: ' || nullif(trim(p_prize), ''), ''),
          'match', 'zone', z, 'tournament:' || tid);
  return tid;
end $$;

-- المنظّم يضيف فريق (من فرق المنطقة) — أو يوافق/يرفض طلب
create or replace function public.add_tournament_team(p_t uuid, p_team text)
returns void language plpgsql security definer set search_path = public as $$
declare t public.tournaments;
begin
  if not public.fn_runs_tournament(p_t) then raise exception 'مش بطولتك'; end if;
  select * into t from public.tournaments where id = p_t;
  if t.status <> 'registration' then raise exception 'القرعة اتعملت خلاص'; end if;
  if (select count(*) from public.tournament_teams where tournament_id = p_t and status = 'approved') >= t.team_count then
    raise exception 'البطولة كملت % فريق', t.team_count;
  end if;
  if not exists (select 1 from public.teams where lower(trim(name)) = lower(trim(p_team))) then
    insert into public.teams (name, zone_id, owner_id) values (trim(p_team), t.zone_id, t.created_by);
  end if;
  insert into public.tournament_teams (tournament_id, team, status) values (p_t, trim(p_team), 'approved')
  on conflict (tournament_id, team) do update set status = 'approved';
end $$;

-- كابتن فريق يطلب يشارك (اسم الفريق + موبايل) → إشعار لمنظّم البطولة
create or replace function public.request_tournament_team(p_t uuid, p_team text, p_phone text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare t public.tournaments;
begin
  perform public.fn_assert_active();
  select * into t from public.tournaments where id = p_t;
  if not found or t.status <> 'registration' then raise exception 'التسجيل مقفول'; end if;
  if char_length(trim(p_team)) not between 2 and 40 then raise exception 'اسم الفريق من ٢ لـ ٤٠ حرف'; end if;
  insert into public.tournament_teams (tournament_id, team, status, captain_id, phone, note)
  values (p_t, trim(p_team), 'pending', auth.uid(), left(trim(p_phone), 20), nullif(left(trim(p_note), 200), ''));
  insert into public.notifications (title, body, kind, user_id, link)
  values ('📝 فريق عايز يشارك: ' || trim(p_team), t.name, 'status', t.created_by, 'tournament:' || p_t);
exception when unique_violation then
  raise exception 'الاسم ده متسجّل في البطولة';
end $$;

create or replace function public.review_tournament_team(p_t uuid, p_team text, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
declare cap uuid;
begin
  if not public.fn_runs_tournament(p_t) then raise exception 'مش بطولتك'; end if;
  select captain_id into cap from public.tournament_teams where tournament_id = p_t and team = p_team;
  if p_approve then
    perform public.add_tournament_team(p_t, p_team);
  else
    update public.tournament_teams set status = 'rejected' where tournament_id = p_t and team = p_team;
  end if;
  if cap is not null then
    insert into public.notifications (title, body, kind, user_id, link)
    values (case when p_approve then '✓ فريقك اتقبل في البطولة' else 'طلب فريقك اترفض' end, p_team, 'status', cap,
            'tournament:' || p_t);
  end if;
end $$;

-- القرعة: الفرق بتتخلط عشوائي → الجدول بيتعمل لوحده حسب النظام
create or replace function public.draw_tournament(p_t uuid)
returns void language plpgsql security definer set search_path = public as $$
declare t public.tournaments; teams text[]; g int; i int; lbl text;
begin
  if not public.fn_runs_tournament(p_t) then raise exception 'مش بطولتك'; end if;
  select * into t from public.tournaments where id = p_t for update;
  if t.status <> 'registration' then raise exception 'القرعة اتعملت خلاص'; end if;
  select array_agg(team order by random()) into teams
  from public.tournament_teams where tournament_id = p_t and status = 'approved';
  if coalesce(array_length(teams, 1), 0) < 2 then raise exception 'محتاج فريقين على الأقل'; end if;
  update public.tournaments set status = 'running' where id = p_t;
  if t.format = 'league' then
    perform public.fn_round_robin(p_t, teams, 'الدوري', 0);
  elsif t.format = 'knockout' then
    perform public.fn_build_bracket(p_t, teams);
  else
    g := greatest(t.groups_count, 2);
    for i in 1 .. array_length(teams, 1) loop
      update public.tournament_teams set group_label = chr(64 + ((i - 1) % g) + 1)
      where tournament_id = p_t and team = teams[i];
    end loop;
    for i in 1 .. g loop
      lbl := chr(64 + i);
      perform public.fn_round_robin(p_t,
        array(select team from public.tournament_teams where tournament_id = p_t and group_label = lbl and status = 'approved'),
        'مجموعة ' || lbl, 0);
    end loop;
  end if;
  perform public.fn_admin_log('draw_tournament', p_t::text, jsonb_build_object('name', t.name));
  insert into public.notifications (title, body, kind, audience, zone_id, link)
  values ('🎲 قرعة ' || t.name || ' اتعملت', 'شوف الجدول وماتشات فريقك', 'match', 'zone', t.zone_id, 'tournament:' || p_t);
end $$;

-- المجموعات خلصت → أول اتنين من كل مجموعة لخروج المغلوب (الأول ضد تاني المجموعة اللي جنبه)
create or replace function public.start_knockout(p_t uuid)
returns void language plpgsql security definer set search_path = public as $$
declare t public.tournaments; q text[] := '{}'; g int; i int; a text; b text;
begin
  if not public.fn_runs_tournament(p_t) then raise exception 'مش بطولتك'; end if;
  select * into t from public.tournaments where id = p_t;
  if t.format <> 'groups' or t.status <> 'running' then raise exception 'البطولة مش في دور المجموعات'; end if;
  if exists (select 1 from public.tournament_bracket where tournament_id = p_t) then raise exception 'خروج المغلوب بدأ خلاص'; end if;
  if exists (select 1 from public.matches where tournament_id = p_t and status <> 'finished') then
    raise exception 'لسه فيه ماتشات مجموعات مخلصتش';
  end if;
  g := t.groups_count;
  for i in 1 .. g by 2 loop
    a := chr(64 + i); b := chr(64 + least(i + 1, g));
    q := q || array[
      (select s.team from public.tournament_standings(p_t) s where s.group_label = a offset 0 limit 1),
      (select s.team from public.tournament_standings(p_t) s where s.group_label = b offset 1 limit 1),
      (select s.team from public.tournament_standings(p_t) s where s.group_label = b offset 0 limit 1),
      (select s.team from public.tournament_standings(p_t) s where s.group_label = a offset 1 limit 1)];
  end loop;
  -- من غير تكرار (المجموعة الأخيرة لو العدد فردي) وبنفس الترتيب
  q := array(select u.x from unnest(q) with ordinality u(x, o)
             where u.x is not null
               and u.o = (select min(v.o) from unnest(q) with ordinality v(x, o) where v.x = u.x)
             order by u.o);
  perform public.fn_build_bracket(p_t, q);
  insert into public.notifications (title, body, kind, audience, zone_id, link)
  values ('⚔️ خروج المغلوب بدأ: ' || t.name, 'المتأهلين اتعرفوا — شوف الشجرة', 'match', 'zone', t.zone_id, 'tournament:' || p_t);
end $$;

-- تعادل في خروج المغلوب → المنظّم يختار الفايز (ضربات جزاء)
create or replace function public.set_match_winner(p_match uuid, p_team text)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  select * into m from public.matches where id = p_match;
  if m.tournament_id is null or not public.fn_runs_tournament(m.tournament_id) then raise exception 'مش مسموح'; end if;
  if m.status <> 'finished' then raise exception 'الماتش لسه مخلصش'; end if;
  if not (p_team = any(m.teams)) then raise exception 'الفريق ده مش في الماتش'; end if;
  update public.matches set winner = p_team where id = p_match;
end $$;

-- توقّع البطل: لحد ما أول ماتش في البطولة يبدأ
create or replace function public.predict_champion(p_t uuid, p_team text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_assert_active();
  if public.fn_is_zone_manager() then raise exception 'حساب المدير مش بيتوقّع'; end if;
  if not exists (select 1 from public.tournament_teams where tournament_id = p_t and team = p_team and status = 'approved') then
    raise exception 'الفريق ده مش في البطولة';
  end if;
  if exists (select 1 from public.matches where tournament_id = p_t and date_time <= now())
     or exists (select 1 from public.tournaments where id = p_t and status = 'finished') then
    raise exception 'التوقّع اتقفل — البطولة بدأت';
  end if;
  insert into public.tournament_predictions (tournament_id, user_id, team) values (p_t, auth.uid(), p_team)
  on conflict (tournament_id, user_id) do update set team = excluded.team, created_at = now();
end $$;

-- الجوايز: الهداف · أحسن حارس · أحسن لاعب (أعلى نقط في ماتشات البطولة)
create or replace function public.tournament_awards(p_t uuid)
returns table(award text, player_id uuid, name text, team text, value int)
language sql stable security definer set search_path = public as $$
  with ms as (select id from public.matches where tournament_id = p_t and review_status <> 'void'),
  pts as (select x.player_id, sum(x.points)::int as p, sum(x.goals)::int as g
          from public.fn_pmp('-infinity', 'infinity') x where x.match_id in (select id from ms) group by x.player_id)
  (select 'scorer', pl.id, pl.name, pl.team, pts.g from pts join public.players pl on pl.id = pts.player_id
   where pts.g > 0 order by pts.g desc, pts.p desc limit 1)
  union all
  (select 'keeper', pl.id, pl.name, pl.team, pts.p from pts join public.players pl on pl.id = pts.player_id
   where pl.position = 'GK' and pts.p > 0 order by pts.p desc limit 1)
  union all
  (select 'mvp', pl.id, pl.name, pl.team, pts.p from pts join public.players pl on pl.id = pts.player_id
   where pts.p > 0 order by pts.p desc limit 1);
$$;

-- بونص التوقعات: تحدّي الجولة (+٥) + توقّع بطل البطولة صح (+١٠)
create or replace function public.fn_user_bonus(p_user uuid)
returns int language sql stable security definer set search_path = public as $$
  select ((select 5 * count(*) from public.predictions pr join public.matches m on m.id = pr.match_id
           where pr.user_id = p_user and m.is_challenge and m.status = 'finished'
             and (m.review_status = 'approved' or public.fn_test_mode())
             and pr.score_a - pr.score_b = m.score_a - m.score_b)
        + (select 10 * count(*) from public.tournament_predictions tp join public.tournaments t on t.id = tp.tournament_id
           where tp.user_id = p_user and t.champion is not null and lower(trim(tp.team)) = lower(trim(t.champion))))::int;
$$;

grant execute on function public.create_tournament(text, text, int, int, timestamptz, text, text, int) to authenticated;
grant execute on function public.add_tournament_team(uuid, text) to authenticated;
grant execute on function public.request_tournament_team(uuid, text, text, text) to authenticated;
grant execute on function public.review_tournament_team(uuid, text, boolean) to authenticated;
grant execute on function public.draw_tournament(uuid) to authenticated;
grant execute on function public.start_knockout(uuid) to authenticated;
grant execute on function public.set_match_winner(uuid, text) to authenticated;
grant execute on function public.predict_champion(uuid, text) to authenticated;
grant execute on function public.tournament_standings(uuid) to authenticated;
grant execute on function public.tournament_awards(uuid) to authenticated;
grant execute on function public.fn_runs_tournament(uuid) to authenticated;

-- ═══ 37. كارت نقط الجولة في الرئيسية ═══
-- متوسط نقط الجولة في منطقتي (اللي عاملين تشكيلة بس) + أعلى نقط وصاحبها (الضغط عليه = تشكيلته).
create or replace function public.round_highlights(p_round timestamptz)
returns table(avg_points int, top_points int, top_user uuid, top_name text)
language sql stable security definer set search_path = public as $$
  with r as (
    select u.user_id, u.points, p.name
    from public.user_round_points u join public.profiles p on p.id = u.user_id
    where u.round_end = p_round and p.role <> 'organizer' and p.is_active
      and p.zone_id is not distinct from (select pr.zone_id from public.profiles pr where pr.id = auth.uid())
  )
  select coalesce(round((select avg(points) from r))::int, 0),
         (select r.points from r order by r.points desc, r.name limit 1),
         (select r.user_id from r order by r.points desc, r.name limit 1),
         (select r.name from r order by r.points desc, r.name limit 1);
$$;
revoke all on function public.round_highlights(timestamptz) from public, anon;
grant execute on function public.round_highlights(timestamptz) to authenticated;

-- نقط اللاعب في كل جولة (صفحة اللاعب): كانت بتقع (صلاحيات fn_pmp) فالويدجت كانت بتفضل تحمّل.
-- دلوقتي security definer وبالجولة الحقيقية (مش رقم الأسبوع القديم).
create or replace function public.player_history(p uuid)
returns table(gw int, points bigint)
language sql stable security definer set search_path = public as $$
  select (row_number() over (order by t.r))::int, t.pts
  from (select public.fn_week_cutoff(m.date_time) as r, coalesce(sum(x.points), 0)::bigint as pts
        from public.fn_pmp('-infinity', 'infinity', p) x
        join public.matches m on m.id = x.match_id
        group by 1) t
  order by t.r;
$$;
grant execute on function public.player_history(uuid) to authenticated;

-- ═══ 38. المراكز: في الخماسي حارس أو لاعب بس ═══
-- أي مركز قديم (دفاع · وسط · هجوم) بيبقى «لاعب» (FWD) — الحسبة كلها أصلًا حارس ولا لا.
update public.players set position = 'FWD' where position is distinct from 'GK' and position is distinct from 'FWD';

-- ═══ 39. الماتش اللي خلص بيتقفل على المنظّم ═══
-- بعد ما الماتش يخلص المنظّم بيشوف بس: لا تشكيلة ولا أحداث ولا تعديل (الأدمن بس يقدر يصلّح).
create or replace function public.fn_organizes(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.matches m join public.profiles p on p.id = auth.uid()
                where m.id = p_match and m.organizer_id = auth.uid() and p.role = 'organizer'
                  and m.status <> 'finished'
                  and m.review_status in ('open', 'pending'));
$$;
grant execute on function public.fn_organizes(uuid) to authenticated;

-- ═══ 40. هدف وتصدّي الجولة من المديرين ═══
-- كل مدير منطقة بيرشّح الأهداف والتصديات من ماتشاته اللي خلصت (لينك فيديو) → كلهم بيتجمعوا في تصويت
-- واحد للجولة في المنطقة → أهل المنطقة بيصوّتوا. أول ترشيح بيفتح التصويت ويبعت إشعار للمنطقة.
alter table public.poll_options add column if not exists added_by uuid references public.profiles(id) on delete set null;

create or replace function public.nominate_award(p_kind text, p_match uuid, p_player uuid, p_video text)
returns uuid language plpgsql security definer set search_path = public as $$
declare m public.matches; pl public.players; v_kind text; v_poll uuid; v_round timestamptz; v_opt uuid;
begin
  if p_kind not in ('goal', 'save') then raise exception 'النوع لازم يبقى هدف أو تصدّي'; end if;
  select * into m from public.matches where id = p_match;
  if m.id is null then raise exception 'الماتش مش موجود'; end if;
  if not (public.is_manager() or (public.is_organizer() and m.organizer_id = auth.uid())) then
    raise exception 'ترشّح من ماتشاتك بس';
  end if;
  if m.status <> 'finished' then raise exception 'رشّح بعد ما الماتش يخلص'; end if;
  if m.review_status = 'void' then raise exception 'الماتش ده اتلغى'; end if;
  if p_video is null or p_video !~* '^https?://\S+$' or length(p_video) > 500 then
    raise exception 'حط لينك فيديو صحيح';
  end if;
  select * into pl from public.players where id = p_player;
  if pl.id is null or not exists (select 1 from public.lineups l where l.match_id = p_match and l.player_id = p_player) then
    raise exception 'اللاعب مش في تشكيلة الماتش';
  end if;
  v_kind := p_kind || '_week';
  v_round := public.fn_week_cutoff(m.date_time);
  select id into v_poll from public.polls
  where kind = v_kind and window_end = v_round and zone_id is not distinct from m.zone_id
  order by created_at desc limit 1;
  if v_poll is null then
    insert into public.polls (kind, question, active, window_end, closes_at, zone_id)
    values (v_kind, case when p_kind = 'goal' then 'هدف الجولة ⚽' else 'تصدّي الجولة 🧤' end, true, v_round,
            case when public.fn_test_mode() then null else v_round + interval '2 days' end, m.zone_id)
    returning id into v_poll;
    if m.zone_id is not null then
      insert into public.notifications (title, body, kind, audience, zone_id)
      values (case when p_kind = 'goal' then '⚽ تصويت هدف الجولة فتح' else '🧤 تصويت تصدّي الجولة فتح' end,
              'اتفرّج على المرشّحين وصوّت لأحلى ' || case when p_kind = 'goal' then 'هدف' else 'تصدّي' end,
              'vote', 'zone', m.zone_id);
    end if;
  elsif not exists (select 1 from public.polls where id = v_poll and active
                    and (closes_at is null or closes_at > now())) then
    raise exception 'تصويت الجولة دي اتقفل';
  end if;
  if exists (select 1 from public.poll_options where poll_id = v_poll and player_id = p_player and match_id = p_match) then
    raise exception 'اللاعب ده مترشّح من الماتش ده قبل كده';
  end if;
  insert into public.poll_options (poll_id, label, player_id, video_url, match_id, added_by)
  values (v_poll, pl.name || ' · ' || pl.team, p_player, p_video, p_match, auth.uid())
  returning id into v_opt;
  return v_opt;
end $$;

-- المدير يشيل ترشيحه (والأدمن أي ترشيح) — الأصوات اللي عليه بتتمسح معاه.
create or replace function public.remove_award_nomination(p_option uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from public.poll_options o
  where o.id = p_option
    and (public.is_manager() or (o.added_by = auth.uid() and public.is_organizer()))
    and exists (select 1 from public.polls p where p.id = o.poll_id and p.kind in ('goal_week', 'save_week'));
  if not found then raise exception 'مينفعش تشيل الترشيح ده'; end if;
end $$;

-- ترشيحاتي (المدير) في آخر ٣٠ يوم
create or replace function public.my_award_nominations()
returns table(option_id uuid, kind text, label text, video_url text, match_id uuid, votes bigint, open boolean)
language sql stable security definer set search_path = public as $$
  select o.id, p.kind, o.label, o.video_url, o.match_id,
         (select count(*) from public.poll_votes v where v.option_id = o.id),
         p.active and (p.closes_at is null or p.closes_at > now())
  from public.poll_options o join public.polls p on p.id = o.poll_id
  where o.added_by = auth.uid() and p.kind in ('goal_week', 'save_week')
    and p.created_at > now() - interval '30 days'
  order by p.created_at desc, o.label;
$$;
revoke all on function public.nominate_award(text, uuid, uuid, text) from public, anon;
revoke all on function public.remove_award_nomination(uuid) from public, anon;
revoke all on function public.my_award_nominations() from public, anon;
grant execute on function public.nominate_award(text, uuid, uuid, text) to authenticated;
grant execute on function public.remove_award_nomination(uuid) to authenticated;
grant execute on function public.my_award_nominations() to authenticated;

-- ═══ 41. منع المراهنات ═══
-- أي حد يعرف إن مدير أو حد في منطقة بيستخدم الأبلكيشن في مراهنات يبلّغ → الأدمنز بيوصلهم إشعار
-- ويحققوا → لو اتثبت: بان نهائي.
create table if not exists public.betting_reports (
  id         uuid primary key default gen_random_uuid(),
  reporter   uuid references public.profiles(id) on delete set null default auth.uid(),
  zone_id    int references public.zones(id),
  suspect    text not null check (char_length(trim(suspect)) between 2 and 120),
  details    text not null check (char_length(trim(details)) between 10 and 1000),
  status     text not null default 'open' check (status in ('open', 'investigating', 'proven', 'dismissed')),
  created_at timestamptz not null default now()
);
create index if not exists betting_reports_status on public.betting_reports(status, created_at desc);
alter table public.betting_reports enable row level security;
drop policy if exists "betting reports read" on public.betting_reports;
create policy "betting reports read" on public.betting_reports for select to authenticated
  using (reporter = auth.uid() or public.is_manager());
drop policy if exists "betting reports admin update" on public.betting_reports;
create policy "betting reports admin update" on public.betting_reports for update to authenticated
  using (public.is_manager()) with check (public.is_manager());

-- p_user: لو البلاغ من صفحة يوزر بعينه
alter table public.betting_reports add column if not exists suspect_user uuid references public.profiles(id) on delete set null;
drop function if exists public.report_betting(text, text);
create or replace function public.report_betting(p_suspect text, p_details text, p_user uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare rid uuid;
begin
  if p_user = auth.uid() then raise exception 'مينفعش تبلّغ عن نفسك'; end if;
  if auth.uid() is null then raise exception 'سجّل دخول الأول'; end if;
  if (select count(*) from public.betting_reports
      where reporter = auth.uid() and created_at > now() - interval '1 day') >= 5 then
    raise exception 'بعتّ بلاغات كتير النهارده — الإدارة بتراجعهم';
  end if;
  insert into public.betting_reports (reporter, zone_id, suspect, details, suspect_user)
  values (auth.uid(), (select zone_id from public.profiles where id = auth.uid()), trim(p_suspect), trim(p_details), p_user)
  returning id into rid;
  insert into public.notifications (title, body, kind, user_id, link)
  select '🚫 بلاغ مراهنات', trim(p_suspect) || ' — ' || left(trim(p_details), 100), 'admin', pr.id, 'admin:betting'
  from public.profiles pr where pr.role = 'manager';
  return rid;
end $$;
revoke all on function public.report_betting(text, text, uuid) from public, anon;
grant execute on function public.report_betting(text, text, uuid) to authenticated;

-- (أدمن) البلاغات بأسماء اللي بلّغوا ومناطقهم + حساب المبلَّغ عنه (لو البلاغ من صفحته) وحالته
drop function if exists public.admin_betting_reports();
create or replace function public.admin_betting_reports()
returns table(id uuid, reporter_name text, zone text, suspect text, details text, status text,
              created_at timestamptz, suspect_user uuid, suspect_active boolean, suspect_role text)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query
  select r.id, coalesce(p.name, '—'), coalesce(z.name, '—'), r.suspect, r.details, r.status, r.created_at,
         r.suspect_user, su.is_active, su.role
  from public.betting_reports r
  left join public.profiles p on p.id = r.reporter
  left join public.zones z on z.id = r.zone_id
  left join public.profiles su on su.id = r.suspect_user
  order by (r.status in ('open', 'investigating')) desc, r.created_at desc
  limit 200;
end $$;
revoke all on function public.admin_betting_reports() from public, anon;
grant execute on function public.admin_betting_reports() to authenticated;

-- (أدمن) قرار البلاغ: بيتحقق فيه · مش صحيح · اتثبت — ولو اتثبت والبلاغ على حساب بعينه: بان نهائي للحساب.
create or replace function public.resolve_betting_report(p_id uuid, p_status text)
returns boolean language plpgsql security definer set search_path = public as $$
declare r public.betting_reports; banned boolean := false;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  if p_status not in ('investigating', 'proven', 'dismissed') then raise exception 'حالة غلط'; end if;
  update public.betting_reports set status = p_status where id = p_id returning * into r;
  if r.id is null then raise exception 'البلاغ مش موجود'; end if;
  if p_status = 'proven' and r.suspect_user is not null then
    if exists (select 1 from public.profiles where id = r.suspect_user and role <> 'manager' and is_active) then
      perform public.set_user_active(r.suspect_user, false);   -- بيتسجّل في سجل العمليات وبيوصله إشعار
      banned := true;
    end if;
    -- باقي البلاغات المفتوحة على نفس الحساب اتقفلت معاه
    update public.betting_reports set status = 'proven'
    where suspect_user = r.suspect_user and status in ('open', 'investigating');
  end if;
  return banned;
end $$;
revoke all on function public.resolve_betting_report(uuid, text) from public, anon;
grant execute on function public.resolve_betting_report(uuid, text) to authenticated;

