-- الجزء 7 من 7 — شغّل الأجزاء بالترتيب (اتعمل من migrate_all.sql بـ tool/split_sql.py)
-- ═══ 51-ك. الكابتن · فرق البطولات لكباتنها · المشرف بيوثّق · طلب توثيق الملعب ═══
-- ١) الكابتن: أي يوزر يعمل فريق واحد من «فريقي» ويضيف لاعيبته، ويفضل يلعب فانتازي (بس ميختارش لاعيبة فريقه).
--    كده «كابتن الخصم بيأكّد» بيشتغل مع أي فريق ليه كابتن على الأبلكيشن — مش المديرين بس.
-- ٢) الفريق اللي بيتسجّل في بطولة بيتعمل باسم الكابتن اللي طلب (مش صاحب الملعب)، وفريق بنفس الاسم
--    في منطقة تانية = لازم اسم تاني.
-- ٣) مشرف المنطقة بيوثّق اللاعيبة والملاعب في منطقته — الأدمن مبقاش لوحده.
-- ٤) صاحب الملعب يطلب التوثيق من الأبلكيشن → الأدمن ومشرف المنطقة يوصلهم إشعار.
-- (حد ٣ لاعيبة من نفس الفريق في الفانتازي: في save_round_picks · قسم ٢٧ القديم اتشال)

drop function if exists public.request_late_match(text[], timestamptz, text);
drop function if exists public.admin_late_match_requests();
drop function if exists public.review_late_match(uuid, boolean);
drop table if exists public.late_match_requests;

-- ── الكابتن ──
create or replace function public.is_captain()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.teams where owner_id = auth.uid()) and public.fn_me_active();
$$;
grant execute on function public.is_captain() to authenticated;

-- المدير: فرق كتير · اليوزر: فريق واحد (هو كابتنه)
drop policy if exists "teams organizer insert" on public.teams;
create policy "teams organizer insert" on public.teams for insert to authenticated
  with check (public.fn_me_active()
              and (public.is_organizer() or not exists (select 1 from public.teams t where t.owner_id = auth.uid())));

-- اللاعيبة: المدير · صاحب الملعب الموثّق · الكابتن — والـ trigger بيتأكد إن الفريق بتاعه
drop policy if exists "players organizer insert" on public.players;
create policy "players organizer insert" on public.players for insert to authenticated
  with check ((public.is_organizer() or public.is_venue_host() or public.is_captain())
              and (select count(*) from public.players p where p.created_by = auth.uid()) < 300);
drop policy if exists "players organizer update" on public.players;
create policy "players organizer update" on public.players for update to authenticated
  using (created_by = auth.uid() and (public.is_organizer() or public.is_venue_host() or public.is_captain()))
  with check (created_by = auth.uid());

-- ── البطولة: الفريق لكابتنه ──
create or replace function public.request_tournament_team(p_t uuid, p_team text, p_phone text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare t public.tournaments; tm public.teams;
begin
  perform public.fn_assert_active();
  select * into t from public.tournaments where id = p_t;
  if not found or t.status <> 'registration' then raise exception 'التسجيل مقفول'; end if;
  if char_length(trim(p_team)) not between 2 and 40 then raise exception 'اسم الفريق من ٢ لـ ٤٠ حرف'; end if;
  select * into tm from public.teams where lower(trim(name)) = lower(trim(p_team));
  if tm.id is not null and tm.owner_id is distinct from auth.uid() then
    raise exception 'الاسم ده لفريق تاني — لو ده فريقك خلّي كابتنه يسجّل، أو اختار اسم تاني';
  end if;
  if tm.id is not null and tm.zone_id is distinct from t.zone_id then
    raise exception 'فريقك من منطقة تانية غير منطقة البطولة';
  end if;
  insert into public.tournament_teams (tournament_id, team, status, captain_id, phone, note)
  values (p_t, trim(p_team), 'pending', auth.uid(), left(trim(p_phone), 20), nullif(left(trim(p_note), 200), ''));
  insert into public.notifications (title, body, kind, user_id, link)
  values ('📝 فريق عايز يشارك: ' || trim(p_team), t.name, 'status', t.created_by, 'tournament:' || p_t);
exception when unique_violation then
  raise exception 'الاسم ده متسجّل في البطولة';
end $$;

create or replace function public.add_tournament_team(p_t uuid, p_team text)
returns void language plpgsql security definer set search_path = public as $$
declare t public.tournaments; tm public.teams; cap uuid;
begin
  if not public.fn_runs_tournament(p_t) then raise exception 'مش بطولتك'; end if;
  select * into t from public.tournaments where id = p_t;
  if t.status <> 'registration' then raise exception 'القرعة اتعملت خلاص'; end if;
  if (select count(*) from public.tournament_teams where tournament_id = p_t and status = 'approved') >= t.team_count then
    raise exception 'البطولة كملت % فريق', t.team_count;
  end if;
  select * into tm from public.teams where lower(trim(name)) = lower(trim(p_team));
  if tm.id is null then
    -- فريق جديد: باسم الكابتن اللي طلب (ولو المنظّم ضافه بنفسه: باسم المنظّم)
    select captain_id into cap from public.tournament_teams
    where tournament_id = p_t and lower(trim(team)) = lower(trim(p_team));
    insert into public.teams (name, zone_id, owner_id) values (trim(p_team), t.zone_id, coalesce(cap, t.created_by));
  elsif tm.zone_id is not null and tm.zone_id <> t.zone_id then
    raise exception 'فيه فريق اسمه «%» في منطقة تانية — غيّر الاسم', trim(p_team);
  end if;
  insert into public.tournament_teams (tournament_id, team, status) values (p_t, trim(p_team), 'approved')
  on conflict (tournament_id, team) do update set status = 'approved';
end $$;

-- ── المشرف بيوثّق في منطقته ──
create or replace function public.fn_supervises(p_zone int)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_manager() or (p_zone is not null and exists (
    select 1 from public.profiles where id = auth.uid() and supervisor_zone = p_zone and is_active));
$$;

create or replace function public.trg_claim_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare pn text; un text; z int;
begin
  select name, zone_id into pn, z from public.players where id = new.player_id;
  select name into un from public.profiles where id = new.user_id;
  insert into public.notifications (title, body, kind, user_id, link)
  select '🪪 طلب توثيق لاعب', coalesce(un, 'يوزر') || ' بيقول إنه ' || coalesce(pn, ''), 'status', p.id, 'admin:claims'
  from public.profiles p
  where (p.role = 'manager' or (p.supervisor_zone = z and p.is_active)) and p.id <> new.user_id;
  return new;
end $$;

create or replace function public.review_claim(p_claim uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
declare c public.player_claims; pn text; z int;
begin
  select * into c from public.player_claims where id = p_claim;
  if not found or c.status <> 'pending' then raise exception 'الطلب مش موجود أو اتراجع'; end if;
  select name, zone_id into pn, z from public.players where id = c.player_id;
  if not public.fn_supervises(z) then raise exception 'للأدمن أو مشرف المنطقة بس'; end if;
  if c.user_id = auth.uid() and not public.is_manager() then raise exception 'مينفعش توثّق نفسك'; end if;
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
    values ('طلب التوثيق اترفض', 'الإدارة مقدرتش تأكّد إنك ' || pn, 'status', c.user_id);
  end if;
  perform public.fn_admin_log(case when p_approve then 'approve_claim' else 'reject_claim' end, p_claim::text,
                              jsonb_build_object('player', pn));
end $$;
grant execute on function public.review_claim(uuid, boolean) to authenticated;

create or replace function public.pending_claims()
returns table(id uuid, player_id uuid, player_name text, team text, user_id uuid, user_name text,
              phone text, note text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
declare sz int := (select pp.supervisor_zone from public.profiles pp where pp.id = auth.uid() and pp.is_active);
begin
  if not public.is_manager() and sz is null then raise exception 'للأدمن أو مشرف المنطقة بس'; end if;
  return query select c.id, c.player_id, pl.name, pl.team, c.user_id, pr.name, pr.phone, c.note, c.created_at
    from public.player_claims c join public.players pl on pl.id = c.player_id
    join public.profiles pr on pr.id = c.user_id
    where c.status = 'pending' and (public.is_manager() or (pl.zone_id = sz and c.user_id <> auth.uid()))
    order by c.created_at;
end $$;
grant execute on function public.pending_claims() to authenticated;

-- ── توثيق الملعب: طلب من صاحبه → الأدمن أو مشرف المنطقة يوثّق أو يرفض ──
create or replace function public.request_venue_verification(p_venue uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v public.venues; who text;
begin
  perform public.fn_assert_active();
  select * into v from public.venues where id = p_venue;
  if v.id is null or v.owner_id is distinct from auth.uid() then raise exception 'مش ملعبك'; end if;
  if v.verified then raise exception 'ملعبك موثّق خلاص'; end if;
  if v.zone_id is null then raise exception 'اختار منطقتك الأول من «حسابي»'; end if;
  if v.verify_requested_at > now() - interval '24 hours' then
    raise exception 'طلبك اتبعت — الإدارة هتكلّمك (تقدر تفكّرهم بعد ٢٤ ساعة)';
  end if;
  update public.venues set verify_requested_at = now() where id = p_venue;
  select name || coalesce(' · ' || phone, '') into who from public.profiles where id = auth.uid();
  insert into public.notifications (title, body, kind, user_id, link)
  select '🏟️ طلب توثيق ملعب', v.name || ' — ' || coalesce(who, ''), 'status', p.id, 'admin:venues'
  from public.profiles p
  where (p.role = 'manager' or (p.supervisor_zone = v.zone_id and p.is_active)) and p.id <> auth.uid();
end $$;
grant execute on function public.request_venue_verification(uuid) to authenticated;

-- (أدمن أو مشرف المنطقة) توثيق · شيل التوثيق · رفض الطلب
create or replace function public.verify_venue(p_venue uuid, p_on boolean)
returns void language plpgsql security definer set search_path = public as $$
declare v public.venues;
begin
  select * into v from public.venues where id = p_venue;
  if v.id is null then raise exception 'الملعب مش موجود'; end if;
  if not public.fn_supervises(v.zone_id) or (v.owner_id = auth.uid() and not public.is_manager()) then
    raise exception 'للأدمن أو مشرف المنطقة بس';
  end if;
  update public.venues set verified = p_on, verify_requested_at = null where id = p_venue;
  perform public.fn_admin_log(case when p_on then 'verify_venue' else 'unverify_venue' end, p_venue::text,
                              jsonb_build_object('name', v.name));
  if v.owner_id is not null and p_on and not v.verified then
    insert into public.notifications (title, body, kind, user_id, link)
    values ('✅ ملعبك اتوثّق', v.name || ' — تقدر دلوقتي تعمل بطولات وتعلن لأهل منطقتك عن أي جديد',
            'event', v.owner_id, 'venue:' || p_venue);
  elsif v.owner_id is not null and not p_on and not v.verified and v.verify_requested_at is not null then
    insert into public.notifications (title, body, kind, user_id, link)
    values ('طلب توثيق ملعبك اترفض', v.name || ' — كلّم الإدارة لو محتاج تفاصيل', 'event', v.owner_id,
            'venue:' || p_venue);
  end if;
end $$;
grant execute on function public.verify_venue(uuid, boolean) to authenticated;

-- الطلبات المستنية (الأدمن: الكل · المشرف: منطقته)
create or replace function public.pending_venues()
returns table(id uuid, name text, address text, owner_id uuid, owner_name text, owner_phone text,
              zone_id int, requested_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
declare sz int := (select pp.supervisor_zone from public.profiles pp where pp.id = auth.uid() and pp.is_active);
begin
  if not public.is_manager() and sz is null then raise exception 'للأدمن أو مشرف المنطقة بس'; end if;
  return query select v.id, v.name, v.address, v.owner_id, p.name, p.phone, v.zone_id, v.verify_requested_at
    from public.venues v left join public.profiles p on p.id = v.owner_id
    where v.verify_requested_at is not null and not v.verified
      and (public.is_manager() or (v.zone_id = sz and v.owner_id is distinct from auth.uid()))
    order by v.verify_requested_at;
end $$;
grant execute on function public.pending_venues() to authenticated;

-- ═══ 51-ل. الكابتنين لازم يأكّدوا · المدير بيدير ماتش بين فريقين كباتن · الكابتن بيبعت تشكيلة فريقه ═══
-- ١) كباتن الماتش (captains) = أصحاب الفريقين اللي مش المدير. الماتش مبيتعتمدش بتأكيد كابتن واحد:
--    لازم كل الكباتن يأكّدوا (ولو المدير صاحب فريق، هو اللي حاطط النتيجة فتأكيده ضمني).
--    أي اعتراض من أي حد = الإدارة تحكم. المدير صاحب الفريقين (مفيش كباتن) = الأدمن/المشرف أو المدير الموثوق.
-- ٢) المدير يقدر يعمل ماتش بين أي فريقين في منطقته ليهم كباتن على الأبلكيشن (مش لازم واحد منهم بتاعه).
-- ٣) الكابتن بيبعت تشكيلة فريقه للماتش → المدير يوصله إشعار → يطبّقها بزرار → «أبلغ اليوزرز إن التشكيلة نزلت».
alter table public.matches add column if not exists captains uuid[] not null default '{}';

create or replace function public.fn_match_captains(p_teams text[], p_org uuid)
returns uuid[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(distinct t.owner_id), '{}') from public.teams t
  where lower(trim(t.name)) in (lower(trim(p_teams[1])), lower(trim(p_teams[2])))
    and t.owner_id is not null and t.owner_id is distinct from p_org;
$$;
update public.matches set captains = public.fn_match_captains(teams, organizer_id)
where captains = '{}' and status = 'upcoming' or review_status = 'pending';

-- الفريقين: كل واحد يا إما بتاعي يا إما ليه كابتن على الأبلكيشن — وفي منطقتي
create or replace function public.fn_check_my_teams(p_teams text[])
returns void language plpgsql stable security definer set search_path = public as $$
declare z int := (select zone_id from public.profiles where id = auth.uid());
begin
  if (select count(*) from public.teams t
      where lower(trim(t.name)) in (lower(trim(p_teams[1])), lower(trim(p_teams[2])))
        and t.owner_id is not null) < 2 then
    raise exception 'الفريقين لازم يكونوا مسجّلين وليهم كباتن على الأبلكيشن';
  end if;
  if exists (select 1 from public.teams t
             where lower(trim(t.name)) in (lower(trim(p_teams[1])), lower(trim(p_teams[2])))
               and t.owner_id is distinct from auth.uid() and t.zone_id is distinct from z) then
    raise exception 'فريق الخصم من منطقة تانية';
  end if;
end $$;

create or replace function public.trg_match_opp()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.teams is distinct from old.teams or new.organizer_id is distinct from old.organizer_id then
    new.captains := public.fn_match_captains(new.teams, new.organizer_id);
  else
    new.captains := old.captains;
  end if;
  new.opp_captain := new.captains[1];
  return new;
end $$;

create or replace function public.trg_match_opp_notify()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (title, body, kind, user_id, match_id)
  select '🤝 ماتش لفريقك', new.teams[1] || ' ضد ' || new.teams[2]
           || ' — ابعت تشكيلتك للمدير، ولو الماتش ده مش متفق عليه اعترض بعد ما يخلص', 'review', c, new.id
  from unnest(new.captains) c
  where tg_op = 'INSERT' or not (c = any(old.captains));
  return null;
end $$;

-- الكابتن بيراجع باسم فريقه، وغيره: لاعب موثّق في التشكيلة
create or replace function public.fn_reviewer_team(p_match uuid, p_user uuid)
returns text language sql stable security definer set search_path = public as $$
  select coalesce(
    (select t.name from public.matches m join public.teams t
       on lower(trim(t.name)) in (lower(trim(m.teams[1])), lower(trim(m.teams[2]))) and t.owner_id = p_user
     where m.id = p_match and p_user = any(m.captains) limit 1),
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
    select c as uid, '🧢 أكّد نتيجة ماتشك (إنت الكابتن)' as title from unnest(m.captains) c
    union all
    select pl.user_id, '📋 أكّد ورقة الماتش' from public.lineups l join public.players pl on pl.id = l.player_id
    where l.match_id = m.id and pl.user_id is not null and pl.user_id is distinct from m.organizer_id
  ) x
  where m.id = p_match
  order by x.uid, x.title desc;
$$;

-- كل الكباتن أكّدوا؟
create or replace function public.fn_captains_ok(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (
    select 1 from public.matches m, unnest(m.captains) c
    where m.id = p_match
      and not exists (select 1 from public.match_reviews r where r.match_id = m.id and r.user_id = c and r.ok));
$$;

-- حساب كابتن جديد (أي واحد من الكباتن) أو المدير بيلعب دايمًا ضد نفس الكابتن → يستنى الأدمن
create or replace function public.fn_captain_flags(p_match uuid)
returns text[] language sql stable security definer set search_path = public as $$
  with m as (select * from public.matches where id = p_match)
  select array_remove(array[
    case when exists (select 1 from public.profiles p where p.id = any(m.captains)
                      and p.created_at > now() - interval '7 days')
         then 'fresh_captain' end,
    case when (select count(*) >= 3 and bool_and(x.opp_captain is not distinct from m.opp_captain)
               from (select opp_captain from public.matches
                     where organizer_id = m.organizer_id and status = 'finished' and review_status <> 'void'
                     order by date_time desc limit 5) x)
         then 'closed_pair' end
  ], null)
  from m where cardinality(m.captains) > 0;
$$;

create or replace function public.trg_review_captain()
returns trigger language plpgsql security definer set search_path = public as $$
declare m public.matches; f text[];
begin
  if not new.ok then return null; end if;
  select * into m from public.matches where id = new.match_id;
  if not (new.user_id = any(m.captains)) or m.review_status <> 'pending' then return null; end if;
  if not public.fn_captains_ok(m.id) then return null; end if;   -- لسه كابتن تاني مأكّدش
  f := coalesce(public.fn_captain_flags(m.id), '{}');
  if cardinality(f) = 0 then
    update public.matches set review_status = 'approved', review_due = null where id = m.id;
  else
    update public.matches set flags = array(select distinct unnest(m.flags || f)) where id = m.id;
    insert into public.notifications (title, body, kind, user_id, match_id)
    select '🕵️ تأكيد كابتن محتاج نظرة', m.teams[1] || ' ضد ' || m.teams[2] || ' — '
             || case when 'closed_pair' = any(f) then 'المدير بيلعب دايمًا ضد نفس الكابتن' else 'حساب كابتن جديد' end,
           'review', p.id, m.id
    from public.profiles p
    where p.role = 'manager' or (p.supervisor_zone = m.zone_id and p.id is distinct from m.organizer_id
                                 and not (p.id = any(m.captains)));
  end if;
  return null;
end $$;

-- تأكيد الفريقين بيعتمد بس لو كل الكباتن أكّدوا كمان
create or replace function public.review_match(p_match uuid, p_ok boolean, p_note text default null)
returns text language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); m public.matches; t text; n text := nullif(trim(p_note), '');
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  perform public.fn_assert_active();
  select * into m from public.matches where id = p_match for update;
  if not found or m.review_status <> 'pending' then raise exception 'الماتش مش مستني تأكيد'; end if;
  t := public.fn_reviewer_team(p_match, u);
  if t is null then raise exception 'لازم تكون كابتن أو لاعب موثّق في تشكيلة الماتش'; end if;
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

  if (select review_status from public.matches where id = p_match) = 'approved' then return 'approved'; end if;
  if exists (select 1 from public.match_reviews r where r.match_id = p_match and r.ok and r.team = m.teams[1])
     and exists (select 1 from public.match_reviews r where r.match_id = p_match and r.ok and r.team = m.teams[2])
     and public.fn_captains_ok(p_match) then
    update public.matches set review_status = 'approved', review_due = null where id = p_match;
    return 'approved';
  end if;
  return 'ok';
end $$;
grant execute on function public.review_match(uuid, boolean, text) to authenticated;

-- الكابتن مبيحكمش في ماتشه حتى لو مشرف
create or replace function public.fn_can_judge(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_manager() or exists (
    select 1 from public.matches m join public.profiles p on p.id = auth.uid()
    where m.id = p_match and p.supervisor_zone = m.zone_id and p.is_active
      and auth.uid() is distinct from m.organizer_id and not (auth.uid() = any(m.captains)));
$$;

-- ── تشكيلة الكابتن ──
create table if not exists public.team_lineups (
  match_id   uuid not null references public.matches(id) on delete cascade,
  team       text not null,
  captain_id uuid references public.profiles(id) on delete set null,
  players    jsonb not null,                      -- [{player_id, status}]
  applied    boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (match_id, team)
);
alter table public.team_lineups enable row level security;
drop policy if exists "team lineups read" on public.team_lineups;
create policy "team lineups read" on public.team_lineups for select to authenticated
  using (captain_id = auth.uid() or public.fn_organizes(match_id) or public.is_manager());

create or replace function public.submit_team_lineup(p_match uuid, p_players jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); m public.matches; tm text; n_all int; n_start int; n_gk int; n_bad int;
begin
  perform public.fn_assert_active();
  select * into m from public.matches where id = p_match;
  if m.id is null then raise exception 'الماتش مش موجود'; end if;
  select t.name into tm from public.teams t
  where t.owner_id = u and lower(trim(t.name)) in (lower(trim(m.teams[1])), lower(trim(m.teams[2]))) limit 1;
  if tm is null then raise exception 'إنت مش كابتن فريق في الماتش ده'; end if;
  if m.status <> 'upcoming' or now() >= m.date_time then raise exception 'الماتش بدأ — كلّم المدير'; end if;
  if jsonb_typeof(p_players) <> 'array' then raise exception 'بيانات غلط'; end if;
  select count(*), count(*) filter (where x.status = 'starting'),
         count(*) filter (where x.status = 'starting' and pl.position = 'GK'),
         count(*) filter (where pl.id is null or lower(trim(pl.team)) <> lower(trim(tm))
                          or x.status not in ('starting', 'bench'))
           + count(*) - count(distinct x.player_id)
  into n_all, n_start, n_gk, n_bad
  from jsonb_to_recordset(p_players) as x(player_id uuid, status text)
  left join public.players pl on pl.id = x.player_id;
  if n_bad > 0 then raise exception 'فيه لاعب مش من فريقك'; end if;
  if n_start <> m.format then raise exception 'لازم % أساسيين', m.format; end if;
  if n_gk <> 1 then raise exception 'لازم حارس واحد في الأساسيين'; end if;
  if n_all > 7 then raise exception 'الفريق آخره ٧'; end if;
  insert into public.team_lineups (match_id, team, captain_id, players, applied)
  values (p_match, tm, u, p_players, false)
  on conflict (match_id, team) do update set captain_id = u, players = excluded.players, applied = false,
                                             created_at = now();
  insert into public.notifications (title, body, kind, user_id, match_id, link)
  select '📋 كابتن «' || tm || '» بعت التشكيلة', m.teams[1] || ' ضد ' || m.teams[2] || ' — طبّقها من إدارة الماتش',
         'status', p.id, m.id, 'manage:' || m.id
  from public.profiles p
  where p.id = m.organizer_id or (m.organizer_id is null and p.role = 'manager');
end $$;
grant execute on function public.submit_team_lineup(uuid, jsonb) to authenticated;

-- (منظّم الماتش/الأدمن) طبّق تشكيلة الكابتن: بتستبدل تشكيلة الفريق ده في الماتش
create or replace function public.apply_team_lineup(p_match uuid, p_team text)
returns void language plpgsql security definer set search_path = public as $$
declare tl public.team_lineups;
begin
  if not (public.is_manager() or public.fn_organizes(p_match)) then raise exception 'مش ماتشك'; end if;
  select * into tl from public.team_lineups where match_id = p_match and team = p_team;
  if tl.match_id is null then raise exception 'الكابتن لسه مبعتش تشكيلة'; end if;
  delete from public.lineups l using public.players pl
  where l.match_id = p_match and pl.id = l.player_id and lower(trim(pl.team)) = lower(trim(p_team));
  insert into public.lineups (match_id, player_id, status)
  select p_match, x.player_id, x.status
  from jsonb_to_recordset(tl.players) as x(player_id uuid, status text)
  order by x.status desc;   -- الأساسيين الأول
  update public.team_lineups set applied = true where match_id = p_match and team = p_team;
  if tl.captain_id is not null and tl.captain_id is distinct from auth.uid() then
    insert into public.notifications (title, body, kind, user_id, match_id)
    values ('✓ المدير نزّل تشكيلة فريقك', p_team, 'status', tl.captain_id, p_match);
  end if;
end $$;
grant execute on function public.apply_team_lineup(uuid, text) to authenticated;

-- ═══ 51-م. صاحب الملعب بيأكّد الماتش · الفرق للكباتن بس · المشرف ورا طلبات المديرين · لوحة النمو · الغياب عن الحجز ═══
-- ١) الماتش اللي في ملعب ليه صاحب (مش المدير ولا كابتن فيه): صاحب الملعب بيأكّد إن الماتش اتلعب، وتأكيده شرط
--    للاعتماد زي الكباتن. «ماتلعبش» = الإدارة تحكم. (لو محدش رد: نفس قاعدة الـ ٤ ساعات والمصداقية)
-- ٢) الفرق واللاعيبة وصورهم بقت شغل الكابتن: المدير مبيعملش فرق ولا بيضيف لاعيبة — بيعمل الماتش بين فريقين
--    ليهم كباتن، والكباتن بيبعتوله التشكيلة، وهو يفكّرهم لو اتأخروا.
-- ٣) مشرف المنطقة بيرد على طلبات «عايز أبقى مدير» في منطقته.
-- ٤) لوحة النمو للأدمن: لكل منطقة — اليوزرز · الجداد · الماتشات الأسبوع ده واللي قبله · اللي عملوا تشكيلة · الشير.
-- ٥) الحجز: صاحب الملعب يسجّل «محضرش» بعد الميعاد — حجزين في ٦٠ يوم = الحجز موقوف.
-- ٦) لوجو للملعب (بيظهر على كروت الشير).

-- ── ١) تأكيد صاحب الملعب ──
alter table public.matches add column if not exists venue_ok boolean;   -- null لسه · true اتلعب · false ماتلعبش
alter table public.venues add column if not exists logo_url text;

-- صاحب الملعب المستقل (مش المدير ولا كابتن في الماتش) — null = مفيش
create or replace function public.fn_venue_judge(p_match uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select v.owner_id from public.matches m join public.venues v on v.id = m.venue_id
  where m.id = p_match and v.owner_id is not null and v.owner_id is distinct from m.organizer_id
    and not (v.owner_id = any(m.captains));
$$;

-- كل الكباتن أكّدوا — وصاحب الملعب كمان لو فيه
create or replace function public.fn_captains_ok(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (
      select 1 from public.matches m, unnest(m.captains) c
      where m.id = p_match
        and not exists (select 1 from public.match_reviews r where r.match_id = m.id and r.user_id = c and r.ok))
    and (public.fn_venue_judge(p_match) is null
         or (select venue_ok from public.matches where id = p_match) is true);
$$;

-- تعديل النتيجة بعد النهاية → تأكيد صاحب الملعب يتلغي كمان
create or replace function public.trg_match_venue_ok_reset()
returns trigger language plpgsql as $$
begin
  if old.status = 'finished' and (new.score_a, new.score_b) is distinct from (old.score_a, old.score_b) then
    new.venue_ok := null;
  end if;
  return new;
end $$;
drop trigger if exists matches_venue_ok_reset on public.matches;
create trigger matches_venue_ok_reset before update on public.matches
for each row execute function public.trg_match_venue_ok_reset();

create or replace function public.fn_ask_reviewers(p_match uuid)
returns void language sql security definer set search_path = public as $$
  insert into public.notifications (title, body, kind, user_id, match_id)
  select distinct on (x.uid) x.title,
         m.teams[1] || ' ' || m.score_a || ' - ' || m.score_b || ' ' || m.teams[2] || ' — النتيجة والأهداف صح؟',
         'review', x.uid, m.id
  from public.matches m
  cross join lateral (
    select c as uid, '🧢 أكّد نتيجة ماتشك (إنت الكابتن)' as title from unnest(m.captains) c
    union all
    select pl.user_id, '📋 أكّد ورقة الماتش' from public.lineups l join public.players pl on pl.id = l.player_id
    where l.match_id = m.id and pl.user_id is not null and pl.user_id is distinct from m.organizer_id
  ) x
  where m.id = p_match
  order by x.uid, x.title desc;
  insert into public.notifications (title, body, kind, user_id, match_id, link)
  select '🏟️ الماتش ده اتلعب في ملعبك؟', m.teams[1] || ' ضد ' || m.teams[2] || ' — أكّد من صفحة الملعب',
         'review', public.fn_venue_judge(m.id), m.id, 'venue:' || m.venue_id
  from public.matches m where m.id = p_match and public.fn_venue_judge(m.id) is not null;
$$;

-- (صاحب الملعب) الماتشات اللي مستنية تأكيده في ملعب
create or replace function public.venue_pending_matches(p_venue uuid)
returns setof json language sql stable security definer set search_path = public as $$
  select json_build_object('id', m.id, 'teams', m.teams, 'date_time', m.date_time,
                           'score_a', m.score_a, 'score_b', m.score_b)
  from public.matches m
  where m.venue_id = p_venue and m.review_status = 'pending' and m.venue_ok is null
    and public.fn_venue_judge(m.id) = auth.uid()
  order by m.date_time desc limit 20;
$$;
grant execute on function public.venue_pending_matches(uuid) to authenticated;

create or replace function public.venue_confirm_match(p_match uuid, p_ok boolean, p_note text default null)
returns text language plpgsql security definer set search_path = public as $$
declare m public.matches; f text[]; n text := nullif(trim(p_note), '');
begin
  perform public.fn_assert_active();
  select * into m from public.matches where id = p_match for update;
  if m.id is null or public.fn_venue_judge(p_match) is distinct from auth.uid() then raise exception 'مش ملعبك'; end if;
  if m.review_status <> 'pending' then raise exception 'الماتش مش مستني تأكيد'; end if;
  if not p_ok then
    if n is null then raise exception 'اكتب إيه اللي حصل'; end if;
    update public.matches set venue_ok = false, review_status = 'disputed' where id = p_match;
    insert into public.notifications (title, body, kind, user_id, match_id)
    select '⚠️ صاحب الملعب بيقول الماتش ماتلعبش', m.teams[1] || ' ضد ' || m.teams[2] || ' — ' || left(n, 120),
           'review', p.id, p_match
    from public.profiles p
    where p.role = 'manager' or p.id = m.organizer_id or (p.supervisor_zone = m.zone_id and p.is_active);
    return 'disputed';
  end if;
  update public.matches set venue_ok = true where id = p_match;
  if not public.fn_captains_ok(p_match) then return 'ok'; end if;   -- لسه كابتن مأكّدش
  f := coalesce(public.fn_captain_flags(p_match), '{}');
  if cardinality(f) = 0 then   -- زي تأكيد الكباتن: علامات الكابتن المشبوه بس هي اللي بتوقّف
    update public.matches set review_status = 'approved', review_due = null where id = p_match;
    return 'approved';
  end if;
  update public.matches set flags = array(select distinct unnest(m.flags || f)) where id = p_match;
  return 'ok';
end $$;
grant execute on function public.venue_confirm_match(uuid, boolean, text) to authenticated;

-- ── ٢) الفرق واللاعيبة شغل الكابتن (الأبلكيشن شال «فرقي» من المدير؛ ماتش بين فريقين للمدير = مفيش كباتن = الأدمن يعتمد) ──
-- الكابتن بيوصله «ماتش لفريقك» وبيفتح على «فريقي» يبعت التشكيلة
create or replace function public.trg_match_opp_notify()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (title, body, kind, user_id, match_id, link)
  select '🤝 ماتش لفريقك — ابعت التشكيلة', new.teams[1] || ' ضد ' || new.teams[2]
           || ' — ابعت تشكيلتك للمدير، ولو الماتش ده مش متفق عليه اعترض بعد ما يخلص', 'review', c, new.id, 'captain'
  from unnest(new.captains) c
  where tg_op = 'INSERT' or not (c = any(old.captains));
  return null;
end $$;

-- (منظّم الماتش) فكّر الكابتن يبعت التشكيلة — مرة كل ساعة للفريق
create or replace function public.remind_team_lineup(p_match uuid, p_team text)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches; cap uuid;
begin
  if not (public.is_manager() or public.fn_organizes(p_match)) then raise exception 'مش ماتشك'; end if;
  select * into m from public.matches where id = p_match;
  select t.owner_id into cap from public.teams t
  where lower(trim(t.name)) = lower(trim(p_team)) and p_team = any(m.teams);
  if cap is null or cap = auth.uid() then raise exception 'الفريق ده مالوش كابتن غيرك'; end if;
  insert into public.app_jobs (key) values ('lineup-remind:' || p_match || ':' || lower(p_team) || ':'
                                            || to_char(now(), 'YYYYMMDDHH24')) on conflict do nothing;
  if not found then raise exception 'فكّرته من شوية — استنى ساعة'; end if;
  insert into public.notifications (title, body, kind, user_id, match_id, link)
  values ('⏰ المدير مستني تشكيلة «' || p_team || '»', m.teams[1] || ' ضد ' || m.teams[2], 'status', cap, p_match,
          'captain');
end $$;
grant execute on function public.remind_team_lineup(uuid, text) to authenticated;

-- ── ٣) المشرف ورا طلبات المديرين في منطقته ──
create or replace function public.trg_organizer_request_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare un text; z int;
begin
  select name, zone_id into un, z from public.profiles where id = new.user_id;
  insert into public.notifications (title, body, kind, user_id, link)
  select '🧑‍⚖️ طلب مدير منطقة', coalesce(un, 'يوزر') || coalesce(' — ' || left(new.note, 100), ''), 'status', p.id,
         'admin:organizers'
  from public.profiles p where (p.role = 'manager' or (p.supervisor_zone = z and p.is_active)) and p.id <> new.user_id;
  return new;
end $$;

create or replace function public.pending_organizer_requests()
returns table(id uuid, user_id uuid, user_name text, phone text, note text, player_name text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
declare sz int := (select pp.supervisor_zone from public.profiles pp where pp.id = auth.uid() and pp.is_active);
begin
  if not public.is_manager() and sz is null then raise exception 'للأدمن أو مشرف المنطقة بس'; end if;
  return query
  select r.id, r.user_id, p.name, p.phone, r.note,
         (select pl.name from public.players pl where pl.user_id = r.user_id), r.created_at
  from public.organizer_requests r join public.profiles p on p.id = r.user_id
  where r.status = 'pending' and (public.is_manager() or (p.zone_id = sz and r.user_id <> auth.uid()))
  order by r.created_at;
end $$;
grant execute on function public.pending_organizer_requests() to authenticated;

create or replace function public.review_organizer_request(p_req uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
declare r public.organizer_requests; z int;
begin
  select * into r from public.organizer_requests where id = p_req;
  if not found or r.status <> 'pending' then raise exception 'الطلب مش موجود أو اتراجع'; end if;
  select zone_id into z from public.profiles where id = r.user_id;
  if not public.fn_supervises(z) or (r.user_id = auth.uid() and not public.is_manager()) then
    raise exception 'للأدمن أو مشرف المنطقة بس';
  end if;
  if p_approve and exists (select 1 from public.players where user_id = r.user_id) then
    raise exception 'اليوزر ده موثّق كلاعب — فك التوثيق الأول (المدير مش بيلعب)';
  end if;
  update public.organizer_requests set status = case when p_approve then 'approved' else 'rejected' end,
         reviewed_at = now() where id = p_req;
  perform public.fn_admin_log(case when p_approve then 'approve_manager' else 'reject_manager' end,
                              r.user_id::text, '{}'::jsonb);
  if p_approve then
    update public.profiles set role = 'organizer' where id = r.user_id and role = 'user';
    perform public.fn_leave_fantasy(r.user_id);
    insert into public.notifications (title, body, kind, user_id)
    values ('✓ بقيت مدير منطقة', 'حسابك بقى حساب إدارة: اعمل ماتشات بين فرق الكباتن في منطقتك', 'status', r.user_id);
  else
    insert into public.notifications (title, body, kind, user_id)
    values ('طلب التنظيم اترفض', 'تقدر تكلّم الإدارة وتقدّم تاني', 'status', r.user_id);
  end if;
end $$;
grant execute on function public.review_organizer_request(uuid, boolean) to authenticated;

-- ── ٤) لوحة النمو ──
create table if not exists public.share_events (
  id         bigint generated always as identity primary key,
  user_id    uuid references public.profiles(id) on delete cascade,
  kind       text not null check (char_length(kind) between 1 and 30),
  created_at timestamptz not null default now()
);
create index if not exists share_events_time on public.share_events(created_at desc);
alter table public.share_events enable row level security;   -- مفيش قراية ولا كتابة مباشرة

create or replace function public.log_share(p_kind text)
returns void language sql security definer set search_path = public as $$
  insert into public.share_events (user_id, kind)
  select auth.uid(), left(coalesce(p_kind, 'card'), 30)
  where auth.uid() is not null
    and (select count(*) from public.share_events where user_id = auth.uid() and created_at > now() - interval '1 day') < 50;
$$;
grant execute on function public.log_share(text) to authenticated;

create or replace function public.admin_growth()
returns table(zone_id int, zone_name text, users int, new_users int, matches_week int, matches_prev int,
              pickers int, shares_week int, tournaments int)
language plpgsql stable security definer set search_path = public as $$
declare r timestamptz := public.fn_open_round();
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query
  select z.id, z.name,
    (select count(*)::int from public.profiles p where p.zone_id = z.id and p.role = 'user' and p.is_active),
    (select count(*)::int from public.profiles p where p.zone_id = z.id and p.created_at > now() - interval '7 days'),
    (select count(*)::int from public.matches m where m.zone_id = z.id and m.review_status <> 'void'
       and m.date_time > now() - interval '7 days' and m.date_time <= now()),
    (select count(*)::int from public.matches m where m.zone_id = z.id and m.review_status <> 'void'
       and m.date_time > now() - interval '14 days' and m.date_time <= now() - interval '7 days'),
    (select count(distinct rp.user_id)::int from public.round_picks rp join public.profiles p on p.id = rp.user_id
       where rp.round_end = r and p.zone_id = z.id),
    (select count(*)::int from public.share_events s join public.profiles p on p.id = s.user_id
       where p.zone_id = z.id and s.created_at > now() - interval '7 days'),
    (select count(*)::int from public.tournaments t where t.zone_id = z.id and t.status <> 'finished')
  from public.zones z order by 3 desc;
end $$;
grant execute on function public.admin_growth() to authenticated;

-- ── ٥) الغياب عن الحجز ──
create or replace function public.fn_no_shows(p_user uuid)
returns int language sql stable security definer set search_path = public as $$
  select count(*)::int from public.bookings
  where user_id = p_user and status = 'no_show' and day > current_date - 60;
$$;

create or replace function public.set_booking_status(bid uuid, new_status text)
returns void language plpgsql security definer set search_path = public as $$
declare b public.bookings; is_owner boolean; v public.venues;
begin
  select * into b from public.bookings where id = bid;
  if not found then raise exception 'الحجز مش موجود'; end if;
  select * into v from public.venues where id = b.venue_id;
  is_owner := v.owner_id = auth.uid() or public.is_manager();
  if new_status = 'cancelled' and b.status in ('pending', 'confirmed')
     and (b.user_id = auth.uid() or is_owner) then
    null;
  elsif new_status in ('confirmed', 'rejected') and b.status = 'pending' and is_owner then
    null;
  elsif new_status = 'no_show' and b.status = 'confirmed' and is_owner then
    if (b.day + make_interval(hours => b.hour)) at time zone 'Africa/Cairo' > now() then
      raise exception 'الميعاد لسه مجاش';
    end if;
    insert into public.notifications (title, body, kind, user_id)
    values ('🚫 اتسجّل عليك إنك محضرتش', v.name || ' · ' || to_char(b.day, 'DD/MM')
              || ' — حجزين زي ده في ٦٠ يوم والحجز بيتوقف', 'booking', b.user_id);
  else
    raise exception 'مش مسموح';
  end if;
  update public.bookings set status = new_status where id = bid;
end; $$;
grant execute on function public.set_booking_status(uuid, text) to authenticated;

create or replace function public.trg_booking_noshow_guard()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.fn_no_shows(new.user_id) >= 2 then
    raise exception 'اتسجّل عليك إنك محضرتش حجزين في آخر ٦٠ يوم — الحجز موقوف مؤقتًا';
  end if;
  return new;
end $$;
drop trigger if exists bookings_noshow_guard on public.bookings;
create trigger bookings_noshow_guard before insert on public.bookings
for each row execute function public.trg_booking_noshow_guard();

-- صاحب الملعب بيشوف كام مرة الحاجز محضرش
create or replace function public.booking_list(p_scope text)
returns setof json language sql stable security definer set search_path = public as $$
  select json_build_object(
    'id', b.id, 'venue_id', b.venue_id, 'user_id', b.user_id, 'day', b.day, 'hour', b.hour,
    'status', b.status, 'note', b.note,
    'venues', json_build_object('name', v.name, 'owner_id', v.owner_id),
    'profiles', json_build_object('name', p.name,
       'phone', case when v.owner_id = auth.uid() or public.is_manager() then p.phone end,
       'no_shows', case when v.owner_id = auth.uid() or public.is_manager() then public.fn_no_shows(p.id) end))
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

-- ═══ 51-ن. ماتشات اللاعب في بروفايله ═══
-- من تبويب «اللاعيبة» → بروفايل اللاعب: كل ماتش لعبه (الفريقين · النتيجة · فريقه · أساسي ولا احتياطي)
-- وعمل إيه فيه (جول · أسيست · كلين شيت · …) ونقطه — نفس حسبة النقط (fn_pmp)، الأحدث الأول.
create or replace function public.player_matches(p uuid)
returns table(match_id uuid, teams text[], date_time timestamptz, score_a int, score_b int, status text,
              review_status text, venue_name text, team text, lineup text, points int, goals int, items jsonb)
language sql stable security definer set search_path = public as $$
  select m.id, m.teams, m.date_time, m.score_a, m.score_b, m.status, m.review_status, m.venue_name,
         pl.team, l.status, x.points, x.goals, x.items
  from public.fn_pmp('-infinity', 'infinity', p) x
  join public.matches m on m.id = x.match_id
  join public.players pl on pl.id = x.player_id
  left join public.lineups l on l.match_id = m.id and l.player_id = x.player_id
  where auth.uid() is not null
  order by m.date_time desc
  limit 40;
$$;
grant execute on function public.player_matches(uuid) to authenticated;

-- ═══ 52. القفلة الأخيرة على الدوال (لازم يفضل آخر قسم في الملف) ═══
-- أي دالة جديدة في Postgres بتبقى متاحة للكل (PUBLIC) لوحدها — فالأقسام اللي بعد قسم ٢٥ كانت سايبة دوال
-- داخلية (إعادة حساب النقط · إنشاء ماتشات البطولات · التيك) تتنادى من أي حد حتى من غير تسجيل دخول.
-- هنا بنقفل على كل الدوال مرة واحدة في آخر الملف:
--   • الزائر (anon): ٣ دوال بس — get_app_config (التحديث الإجباري) · phone_taken (التسجيل) · log_events (تسجيل الأخطاء)
--   • اليوزر المسجّل: دوال التطبيق + المساعدات اللي السياسات والـ triggers بتناديها
--   • الدوال الداخلية (fn_ / trg_ بصلاحيات السيرفر): للسيرفر بس (pg_cron والـ triggers)
do $$
declare r record;
  keep text[] := array['fn_can_edit_player', 'fn_check_my_teams', 'fn_ensure_team', 'fn_event_ok', 'fn_is_zone_manager',
                       'fn_mark_late_edit', 'fn_match_score', 'fn_me_active', 'fn_my_league_count', 'fn_organizes',
                       'fn_rating_open', 'fn_reset_reviews', 'fn_team_zone'];
begin
  for r in select p.oid::regprocedure as f, p.proname, p.prosecdef as definer,
                  has_function_privilege('authenticated', p.oid, 'execute') as had
           from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.prokind in ('f', 'p')
             and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e') loop
    execute format('revoke execute on function %s from public, anon', r.f);
    if r.definer and r.proname ~ '^(fn|trg)_' and r.proname <> all(keep) then
      execute format('revoke execute on function %s from authenticated', r.f);
    elsif r.had then
      execute format('grant execute on function %s to authenticated', r.f);
    end if;
  end loop;
end $$;
grant execute on function public.get_app_config() to anon, authenticated;
grant execute on function public.phone_taken(text) to anon, authenticated;
grant execute on function public.log_events(jsonb) to anon, authenticated;   -- أخطاء ما قبل تسجيل الدخول

-- الزائر (من غير تسجيل دخول) مالوش أي صلاحية على الجداول غير قراية المناطق (شاشة التسجيل).
-- الـ RLS كانت مانعاه أصلًا — ده قفل تاني فوقه لو سياسة اتكتبت غلط في يوم.
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
grant select on public.zones to anon;
do $$ begin
  alter default privileges for role postgres in schema public revoke all on tables from anon;
  alter default privileges for role postgres in schema public revoke all on sequences from anon;
exception when others then null; end $$;

-- ═══════════════════════════════════════════════════════════════
-- خلصنا. (اختياري) خلّي نفسك مدير — بدّل الإيميل بإيميلك:
--   update public.profiles set role = 'manager' where email = 'you@email.com';
-- الأدوار: user · organizer (منظّم ماتشات — الأدمن بيوافق على طلبه) · manager (الأدمن)
-- ═══════════════════════════════════════════════════════════════
