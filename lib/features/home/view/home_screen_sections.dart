part of 'home_screen.dart';

extension _HomeViewSections1 on _HomeView {
  List<HomeShortcut> _shortcuts(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return [
      (
        icon: Icons.sports_score_outlined,
        label: 'تحدّي الجولة',
        onTap: () => nav.openOverlay(AppOverlayView.challenge),
      ),
      (icon: Icons.emoji_events_outlined, label: 'البطولات', onTap: () => _push(context, const TournamentsScreen())),
      (icon: Icons.play_circle_outline, label: 'هدف وتصدّي', onTap: () => nav.openOverlay(AppOverlayView.awards)),
      (icon: Icons.star_outline, label: 'تشكيلة الجولة', onTap: () => _push(context, const TeamOfWeekScreen())),
      (icon: Icons.calendar_today_outlined, label: 'الماتشات', onTap: () => nav.openOverlay(AppOverlayView.fixtures)),
      (icon: Icons.location_on_outlined, label: 'احجز ملعب', onTap: () => nav.openOverlay(AppOverlayView.pitch)),
      (icon: Icons.auto_awesome, label: 'المدرّب', onTap: () => nav.openOverlay(AppOverlayView.coach)),
      (
        icon: Icons.location_city_outlined,
        label: 'دوري المناطق',
        onTap: () => _push(context, const ZoneLeagueScreen()),
      ),
    ];
  }

  List<HomeAlert> _alerts(BuildContext context, HomeState s) {
    final uid = userId;
    if (uid == null) return const [];
    final open = s.openRound;
    return [
      if (open != null && !s.roundSaved)
        (
          icon: Icons.warning_amber_rounded,
          text: 'لسه معملتش تشكيلة الجولة — كل لاعب بيتقفل قبل ماتشه بساعة',
          color: AppColors.danger,
          onTap: () => context.read<AppNavCubit>().setTab(AppTab.team),
        ),
      for (final r in s.toReview)
        (
          icon: Icons.fact_check_outlined,
          text: 'أكّد ورقة ماتش ${r.match.teamA} ضد ${r.match.teamB} — النتيجة والأهداف صح؟',
          color: AppColors.black,
          onTap: () => _review(context, r.match),
        ),
      if (s.tieOpen)
        (
          icon: Icons.how_to_vote_outlined,
          text: 'تعادل في تشكيلة الجولة — صوّت مين يدخل',
          color: AppColors.info,
          onTap: () => _push(context, const TeamOfWeekScreen()),
        ),
      for (final m in s.toRate)
        (
          icon: Icons.star_outline_rounded,
          text: 'قيّم لاعيبة ${m.teamA} ضد ${m.teamB} — واختار رجل المباراة',
          color: AppColors.accent,
          onTap: () => _push(context, MatchRatingsScreen(match: m, userId: uid)),
        ),
    ];
  }

  /// نقط الجولة اللي بتتلعب: المتوسط (شمال) · نقطي (النص) · الأعلى (يمين).
  /// نقطي = تفصيلها (مين لعب ومين لسه) + الجولة الجاية · الأعلى = تشكيلة صاحبها · المتوسط للمعلومة بس.
  Widget _pointsHero(BuildContext context, HomeState s) {
    final h = s.highlights;
    final top = h?.topUserId;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.black, AppColors.night],
        ),
        borderRadius: AppRadius.lg,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text(
            'نقط الجولة · ${WeekWindow.live().label}',
            style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Row(
            textDirection: TextDirection.ltr, // المتوسط شمال والأعلى يمين مهما كانت اللغة
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _side('المتوسط', h?.avg ?? 0)),
              Expanded(
                flex: 2,
                child: Pressable(
                  onTap: userId == null ? null : () => _push(context, LiveRoundScreen(userId: userId!)),
                  child: Column(
                    children: [
                      CountUp(
                        value: s.points,
                        style: AppText.h(64, color: AppColors.white, spacingEm: -0.04, height: 0.95),
                      ),
                      Text('نقطك ›', style: AppText.h(12, color: AppColors.accent400)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Pressable(
                  onTap: top == null
                      ? null
                      : () =>
                            _push(context, LiveRoundScreen(userId: top, ownerName: top == userId ? null : h!.topName)),
                  child: _side('الأعلى ›', h?.top ?? 0, sub: h?.topName, color: const Color(0xFFF2C14E)),
                ),
              ),
            ],
          ),
          if (userId != null) ...[
            const SizedBox(height: 12),
            // «جولتك في ٥ سلايدز» — شريحة صغيرة جوه الكارت بدل زرار عريض لوحده
            Pressable(
              onTap: () => RoundWrappedScreen.open(context, WeekWindow.live()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_outline, size: 16, color: AppColors.accent400),
                    const SizedBox(width: 6),
                    Text('جولتك في ٥ سلايدز', style: AppText.h(12, color: AppColors.white)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
