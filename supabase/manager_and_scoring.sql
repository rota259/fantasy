-- ⚠️ ملف قديم — متشغّلوش. كل حاجة (ومعاها التصليحات) في migrate_all.sql
-- ═══════════════════════════════════════════════════════════════
-- المرحلة 1: محرك النقاط الأوتوماتيك + دور المدير
-- الصقه في Supabase → SQL Editor → Run (بعد schema.sql)
-- ═══════════════════════════════════════════════════════════════

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

-- ── إعادة حساب نقاط كل المستخدمين (مجموع التشكيلة + الكابتن ×2) ──
create or replace function public.fn_recalc_users()
returns void language sql as $$
  update public.profiles pr
  set total_points = coalesce((
    select sum(pl.total_points + case when pl.id = pr.captain_id then pl.total_points else 0 end)
    from public.players pl where pl.id::text = any(pr.team)
  ), 0);
$$;

-- ── تريجر: أي تغيير في events → أعد حساب اللاعب + كل المستخدمين ──
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

-- ── تريجر: تغيير التشكيلة/الكابتن → أعد حساب نقاط المستخدم ده ──
create or replace function public.trg_profile_recalc()
returns trigger language plpgsql as $$
begin
  update public.profiles pr set total_points = coalesce((
    select sum(pl.total_points + case when pl.id = new.captain_id then pl.total_points else 0 end)
    from public.players pl where pl.id::text = any(new.team)
  ), 0) where pr.id = new.id;
  return null;
end;
$$;
drop trigger if exists profile_recalc on public.profiles;
create trigger profile_recalc
after update of team, captain_id on public.profiles
for each row execute function public.trg_profile_recalc();

-- (اختياري) خلّي نفسك مدير: بدّل الإيميل بإيميلك
-- update public.profiles set role = 'manager' where email = 'you@email.com';
