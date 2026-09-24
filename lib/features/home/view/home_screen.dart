import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../manager/data/lineup_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../../core/notifications/sound_service.dart';
import '../../matches/widgets/match_format.dart';
import '../../notifications/cubit/notifications_badge_cubit.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/view/notifications_screen.dart';
import '../../pick/data/picks_repository.dart';
import '../../pick/view/match_pick_screen.dart';
import '../../players/data/players_repository.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../squad/data/profile_repository.dart';
import '../../week/data/week_repository.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_shortcuts.dart';
import '../widgets/home_stars.dart';
import '../../points/view/my_points_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return Column(
      children: [
        const StatusArea(),
        Masthead(
          title: 'الخماسي',
          subtitle: 'MATCHDAY · دوري القاهرة',
          titleLeading: _logoTile(),
          trailing: _bell(context),
        ),
        Expanded(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, s) {
              if (s.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _pointsHero(context, s.points),
                  _nextMatch(context, s.nextMatch),
                  HomeShortcuts(onOpen: nav.openOverlay),
                  HomeStars(
                    week: s.topPlayers,
                    today: s.todayPlayers,
                    weekFinal: s.weekFinal,
                    weekLabel: s.weekLabel,
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
      onTap: userId == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyPointsScreen(userId: userId!)),
              ),
      child: Container(
        width: double.infinity,
        color: AppColors.black,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نقاطك · TOTAL POINTS',
                    style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 2),
                Text('$points', style: AppText.h(72, color: AppColors.white, spacingEm: -0.04, height: 0.9)),
              ],
            ),
          ),
          Text('التفاصيل ›', style: AppText.h(12, color: AppColors.accent400)),
        ]),
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
        onTap: () => _openPick(context, m),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الماتش القادم', style: AppText.kicker(color: AppColors.accent)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(17))),
                Text(m.isLocked ? 'اتقفلت' : 'اختر ›',
                    style: AppText.h(13, color: m.isLocked ? AppColors.neutral500 : AppColors.accent)),
              ]),
              const SizedBox(height: 4),
              Text('يقفل ${arabicWeekday(m.deadline)} ${arabicTime(m.deadline)}',
                  style: AppText.body(11, color: AppColors.neutral700)),
            ],
          ),
        ),
      ),
    );
  }

  void _openPick(BuildContext context, GameMatch m) {
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchPickScreen(
          match: m,
          playersRepo: context.read<PlayersRepository>(),
          picksRepo: context.read<PicksRepository>(),
          lineupRepo: context.read<LineupRepository>(),
          userId: userId!,
        ),
      ),
    );
  }

  Widget _logoTile() {
    return Container(
      width: 32, height: 32, alignment: Alignment.center,
      color: AppColors.white,
      child: Text('٥', style: AppText.h(18, color: AppColors.accent)),
    );
  }

  Widget _bell(BuildContext context) {
    final repo = context.read<NotificationsRepository>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.read<NotificationsBadgeCubit>().markSeen();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationsScreen(repo: repo)),
        );
      },
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 34, height: 34, alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppColors.white, width: 2)),
          child: const Icon(Icons.notifications_none, size: 18, color: AppColors.white),
        ),
        BlocBuilder<NotificationsBadgeCubit, int>(
          builder: (context, count) {
            if (count <= 0) return const SizedBox.shrink();
            return Positioned(
              top: -6, right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                alignment: Alignment.center,
                color: AppColors.accent,
                child: Text(count > 99 ? '99+' : '$count',
                    style: AppText.h(9, color: AppColors.white)),
              ),
            );
          },
        ),
      ]),
    );
  }
}
