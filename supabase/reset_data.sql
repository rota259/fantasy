-- ═══════════════════════════════════════════════════════════════
-- بداية جديدة: بيمسح كل داتا الأبلكيشن ويسيب الحسابات.
--
--   بيتمسح: الماتشات والأحداث والتشكيلات · اللاعيبة والفرق · تشكيلات الجولة والنقط
--           الإشعارات · التصويتات · التوقعات · الشارات · الكروت · طلبات التوثيق والمديرين
--           الملاعب والحجوزات · المواسم · سجل العمليات · الدوريات الخاصة
--   بيفضل:   حسابات اليوزرز والأدمنز والمديرين (بأدوارهم ومناطقهم) · المناطق · الدوري العام
--           ونقط كل الناس بترجع صفر.
--
-- ⚠️ مفيش رجوع. شغّله على staging الأول، وعلى prod لما تبقى متأكد
--    (لو عايز نسخة احتياطية: Database → Backups قبل ما تشغّله).
-- التشغيل: SQL Editor → الصق الملف كله → Run. (بعد migrate_all.sql)
-- ═══════════════════════════════════════════════════════════════
begin;

truncate table
  public.events, public.lineups, public.picks, public.round_picks,
  public.user_round_points, public.user_match_points, public.player_round_stats,
  public.predictions, public.match_follows, public.player_ratings, public.match_reviews,
  public.late_match_requests, public.team_of_week,
  public.notifications, public.poll_votes, public.poll_options, public.polls,
  public.chip_uses, public.user_badges, public.player_claims,
  public.auction_bids, public.auctions,
  public.bookings, public.venue_reviews, public.venues,
  public.matches, public.players, public.teams,
  public.seasons, public.organizer_requests, public.admin_log, public.app_jobs
cascade;

-- الدوريات الخاصة (أعضاها بيتمسحوا معاها) — الدوري العام بيفضل
delete from public.leagues where type <> 'global';

-- نقط وإحصائيات كل الحسابات من الصفر
update public.profiles
   set total_points = 0, low_picks = 0, avg_own = 100, badges_dirty = false, captain_id = null, team = '{}',
       league_id = null
 where id is not null;

commit;
