-- ═══════════════════════════════════════════════════════════════
-- تشكيلات الماتشات (المدير بينزّلها قبل الماتش)
-- الصقه في Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════

-- نتأكد إن دالة is_manager موجودة (لو manager_and_scoring.sql لسه ماتشغّلش)
create or replace function public.is_manager()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'manager');
$$;

create table if not exists public.lineups (
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  status     text not null default 'bench',   -- starting | bench  (مش موجود = بره التشكيلة)
  primary key (match_id, player_id)
);

alter table public.lineups enable row level security;

create policy "lineups read" on public.lineups
  for select to authenticated using (true);

create policy "lineups manager write" on public.lineups
  for all to authenticated
  using (public.is_manager()) with check (public.is_manager());
