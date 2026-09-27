import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../../core/zone/zone_scope.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../integrity/data/integrity_repository.dart';
import '../../integrity/view/match_review_screen.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../notifications/cubit/notifications_badge_cubit.dart';
import '../../pick/data/picks_repository.dart';
import '../../points/view/live_round_screen.dart';
import '../../polls/data/polls_repository.dart';
import '../../ratings/view/match_ratings_screen.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../squad/data/profile_repository.dart';
import '../../week/data/week_repository.dart';
import '../../week/data/week_window.dart';
import '../../week/view/team_of_week_screen.dart';
import '../../zones/data/zone.dart';
import '../../zones/data/zones_repository.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_alerts.dart';
import '../widgets/home_bell.dart';
import '../widgets/home_shortcuts.dart';
import '../widgets/star_of_week_card.dart';
import '../../../core/widgets/motion.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (c) => HomeCubit(
            c.read<ProfileRepository>(),
            c.read<MatchesRepository>(),
            c.read<WeekRepository>(),
            c.read<PollsRepository>(),
            c.read<IntegrityRepository>(),
            c.read<PicksRepository>(),
          )..load(userId),
        ),
        BlocProvider(create: (_) => NotificationsBadgeCubit(SoundService())),
      ],
      child: _HomeView(userId: userId),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({this.userId});
  final String? userId;

  void _push(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  List<HomeShortcut> _shortcuts(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return [
      (
        icon: Icons.sports_score_outlined,
        label: 'تحدّي الجولة',
        onTap: () => nav.openOverlay(AppOverlayView.challenge),
      ),
      (icon: Icons.play_circle_outline, label: 'هدف وتصدّي', onTap: () => nav.openOverlay(AppOverlayView.awards)),
      (icon: Icons.star_outline, label: 'تشكيلة الجولة', onTap: () => _push(context, const TeamOfWeekScreen())),
      (icon: Icons.calendar_today_outlined, label: 'الماتشات', onTap: () => nav.openOverlay(AppOverlayView.fixtures)),
      (icon: Icons.location_on_outlined, label: 'احجز ملعب', onTap: () => nav.openOverlay(AppOverlayView.pitch)),
      (icon: Icons.auto_awesome, label: 'المدرّب', onTap: () => nav.openOverlay(AppOverlayView.coach)),
    ];
  }

  Future<void> _review(BuildContext context, GameMatch m) async {
    final cubit = context.read<HomeCubit>();
    final done = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => MatchReviewScreen(match: m)));
    if (done == true) cubit.refresh();
  }

  List<HomeAlert> _alerts(BuildContext context, HomeState s) {
    final uid = userId;
    if (uid == null) return const [];
    final open = s.openRound;
    return [
      if (open != null && !s.roundSaved)
        (
          text: '⚠️ لسه معملتش تشكيلة الجولة — بتقفل ${arabicWeekday(open.deadline)} ${arabicTime(open.deadline)}',
          color: AppColors.danger,
          onTap: () => context.read<AppNavCubit>().setTab(AppTab.team),
        ),
      for (final r in s.toReview)
        (
          text: '📋 أكّد ورقة ماتش ${r.match.teamA} ضد ${r.match.teamB} — النتيجة والأهداف صح؟',
          color: AppColors.black,
          onTap: () => _review(context, r.match),
        ),
      if (s.tieOpen)
        (
          text: '⚖️ تعادل في تشكيلة الجولة — صوّت مين يدخل',
          color: AppColors.info,
          onTap: () => _push(context, const TeamOfWeekScreen()),
        ),
      for (final m in s.toRate)
        (
          text: '⭐ قيّم لاعيبة ${m.teamA} ضد ${m.teamB} — واختار رجل المباراة',
          color: AppColors.accent,
          onTap: () => _push(context, MatchRatingsScreen(match: m, userId: uid)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StatusArea(),
        // اسم منطقة اليوزر (كل اللي في الهوم على مستواها)
        FutureBuilder<Zone?>(
          future: context.read<ZonesRepository>().byId(ZoneScope.current),
          builder: (context, snap) => Masthead(
            title: 'الخماسي',
            subtitle: 'MATCHDAY · ${snap.data?.name ?? 'الخماسي'}',
            titleLeading: const HomeLogo(),
            trailing: const HomeBell(),
          ),
        ),
        Expanded(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, s) {
              if (s.isLoading) return Center(child: CircularProgressIndicator(color: AppColors.accent));
              // الأقسام بتدخل واحدة ورا التانية (ظهور + طلوع خفيف)
              final sections = [
                _pointsHero(context, s.points),
                HomeAlerts(alerts: _alerts(context, s)),
                _nextMatch(context, s.nextMatch, s.openRound),
                HomeShortcuts(items: _shortcuts(context)),
                StarOfWeekCard(
                  star: s.star,
                  isFinal: s.weekFinal,
                  fromPrevious: s.starFromPrevious,
                  label: s.weekLabel,
                ),
                const SizedBox(height: 16),
              ];
              return ListView(
                padding: EdgeInsets.zero,
                children: [for (final (i, w) in sections.indexed) FadeSlideIn(index: i, child: w)],
              );
            },
          ),
        ),
      ],
    );
  }

  /// نقط الجولة اللي بتتلعب — الضغط بيفتح تفصيلها (مين لعب ومين لسه) + تشكيلة الجولة الجاية.
  Widget _pointsHero(BuildContext context, int points) {
    return Pressable(
      onTap: userId == null ? null : () => _push(context, LiveRoundScreen(userId: userId!)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.black, AppColors.night],
          ),
          borderRadius: AppRadius.lg,
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نقط الجولة · ${WeekWindow.live().label}',
                    style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 2),
                  CountUp(
                    value: points,
                    style: AppText.h(72, color: AppColors.white, spacingEm: -0.04, height: 0.9),
                  ),
                ],
              ),
            ),
            Text('التفاصيل ›', style: AppText.h(12, color: AppColors.accent400)),
          ],
        ),
      ),
    );
  }

  /// الماتش الجاي في منطقتك — الضغط بيفتح تشكيلة الجولة.
  Widget _nextMatch(BuildContext context, GameMatch? m, WeekWindow? open) {
    if (m == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('مفيش ماتش قادم في منطقتك دلوقتي', style: AppText.body(13, color: AppColors.neutral600)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Pressable(
        onTap: () => context.read<AppNavCubit>().setTab(AppTab.team),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.line, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الماتش القادم${m.isChallenge ? ' · 🎯 تحدّي الجولة' : ''}',
                style: AppText.kicker(color: AppColors.accent),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(17))),
                  Text('تشكيلتك ›', style: AppText.h(13, color: AppColors.accent)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)}'
                '${open == null ? '' : ' · التشكيلات بتقفل ${arabicWeekday(open.deadline)} ${arabicTime(open.deadline)}'}',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
