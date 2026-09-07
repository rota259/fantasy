import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/blink_dot.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../manager/data/lineup_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../pick/data/picks_repository.dart';
import '../../pick/view/match_pick_screen.dart';
import '../../players/data/players_repository.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../squad/data/profile_repository.dart';
import '../../week/data/models/week_player.dart';
import '../../week/data/week_repository.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_shortcuts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => HomeCubit(
        c.read<ProfileRepository>(),
        c.read<MatchesRepository>(),
        c.read<WeekRepository>(),
      )..load(userId),
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
          trailing: _liveBadge(),
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
                  _pointsHero(s.points),
                  _nextMatch(context, s.nextMatch),
                  HomeShortcuts(onOpen: nav.openOverlay),
                  const SectionHeader(title: 'أبرز نجوم الجولة', kicker: 'TOP OF THE WEEK'),
                  if (s.topPlayers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text('لسه مفيش نقاط', style: AppText.body(12, color: AppColors.neutral600)),
                    ),
                  for (final p in s.topPlayers) _starRow(p),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pointsHero(int points) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نقاطك · TOTAL POINTS',
              style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
          const SizedBox(height: 2),
          Text('$points', style: AppText.h(72, color: AppColors.white, spacingEm: -0.04, height: 0.9)),
        ],
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

  Widget _starRow(WeekPlayer p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        InitialsTile(p.initials, background: AppColors.accent, color: AppColors.white),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: AppText.h(14)),
            Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
          ]),
        ),
        Text('${p.points}', style: AppText.h(20)),
      ]),
    );
  }

  Widget _logoTile() {
    return Container(
      width: 32, height: 32, alignment: Alignment.center,
      color: AppColors.white,
      child: Text('٥', style: AppText.h(18, color: AppColors.accent)),
    );
  }

  Widget _liveBadge() {
    return Transform.rotate(
      angle: -6 * 3.1416 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(border: Border.all(color: AppColors.white, width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const BlinkDot(color: AppColors.white),
          const SizedBox(width: 5),
          Text('LIVE', style: AppText.h(10, color: AppColors.white, spacingEm: 0.14)),
        ]),
      ),
    );
  }
}
