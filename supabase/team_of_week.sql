-- ⚠️ ملف قديم — متشغّلوش. كل حاجة (ومعاها التصليحات) في migrate_all.sql
-- ═══════════════════════════════════════════════════════════════
-- تشكيلة الأسبوع: نقاط كل لاعب في جولة معيّنة (من أحداث ماتشات الجولة)
-- الصقه في SQL Editor → Run (بعد manager_and_scoring.sql)
-- ═══════════════════════════════════════════════════════════════

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
