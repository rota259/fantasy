-- ⚠️ ملف قديم — متشغّلوش. كل حاجة (ومعاها التصليحات) في migrate_all.sql
-- ═══════════════════════════════════════════════════════════════
-- النموذج الجديد: تشكيلة لكل ماتش (٢ من كل فريق + حارس + ٢ احتياطي)
-- + محرك نقاط per-match. الصقه في SQL Editor → Run (بعد manager_and_scoring.sql)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.picks (
  user_id    uuid references public.profiles(id) on delete cascade,
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  status     text not null default 'starting',   -- starting | bench
  is_captain boolean not null default false,
  is_vice    boolean not null default false,     -- كابتن احتياطي
  primary key (user_id, match_id, player_id)
);
alter table public.picks add column if not exists is_vice boolean not null default false;

alter table public.picks enable row level security;
create policy "picks read" on public.picks for select to authenticated using (true);
create policy "picks own write" on public.picks for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══ إعادة حساب نقاط المستخدمين من اختيارات الماتشات (الأساسيين + الكابتن ×2) ═══
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
