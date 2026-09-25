import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../notifications/cubit/notifications_badge_cubit.dart';
import '../../pick/view/match_pick_screen.dart';
import '../../points/view/my_points_screen.dart';
import '../../polls/data/polls_repository.dart';
import '../../ratings/view/match_ratings_screen.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../squad/data/profile_repository.dart';
import '../../week/data/week_repository.dart';
import '../../week/view/team_of_week_screen.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_alerts.dart';
import '../widgets/home_bell.dart';
import '../widgets/home_shortcuts.dart';
import '../widgets/star_of_week_card.dart';

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

  List<HomeAlert> _alerts(BuildContext context, HomeState s) {
    final uid = userId;
    if (uid == null) return const [];
    return [
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
        const Masthead(
          title: 'الخماسي',
          subtitle: 'MATCHDAY · دوري القاهرة',
          titleLeading: HomeLogo(),
          trailing: HomeBell(),
        ),
        Expanded(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, s) {
              if (s.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _pointsHero(context, s.points),
                  HomeAlerts(alerts: _alerts(context, s)),
                  _nextMatch(context, s.nextMatch),
                  HomeShortcuts(items: _shortcuts(context)),
                  StarOfWeekCard(
                    star: s.star,
                    isFinal: s.weekFinal,
                    fromPrevious: s.starFromPrevious,
                    label: s.weekLabel,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// الضغط على النقاط → تفاصيل نقاطك في كل ماتش.
  Widget _pointsHero(BuildContext context, int points) {
    return GestureDetector(
      onTap: userId == null ? null : () => _push(context, MyPointsScreen(userId: userId!)),
      child: Container(
        width: double.infinity,
        color: AppColors.black,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نقاطك · TOTAL POINTS', style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
                  const SizedBox(height: 2),
                  Text('$points', style: AppText.h(72, color: AppColors.white, spacingEm: -0.04, height: 0.9)),
                ],
              ),
            ),
            Text('التفاصيل ›', style: AppText.h(12, color: AppColors.accent400)),
          ],
        ),
      ),
    );
  }

  Widget _nextMatch(BuildContext context, GameMatch? m) {
    if (m == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('مفيش ماتش قادم دلوقتي', style: AppText.body(13, color: AppColors.neutral600)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: userId == null ? null : () => _push(context, MatchPickScreen(match: m, userId: userId!)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
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
                  Text(
                    m.isLocked ? 'اتقفلت' : 'اختر ›',
                    style: AppText.h(13, color: m.isLocked ? AppColors.neutral500 : AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'يقفل ${arabicWeekday(m.deadline)} ${arabicTime(m.deadline)}',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
