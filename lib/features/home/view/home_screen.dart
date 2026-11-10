import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../leagues/view/zone_league_screen.dart';
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
import '../../points/view/round_wrapped_screen.dart';
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
import '../../points/widgets/player_matches_sheet.dart';
import '../widgets/home_alerts.dart';
import '../widgets/home_bell.dart';
import '../widgets/home_shortcuts.dart';
import '../widgets/star_of_week_card.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../tournaments/view/tournaments_screen.dart';

part 'home_screen_sections.dart';
part 'home_screen_sections2.dart';

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

  Future<void> _review(BuildContext context, GameMatch m) async {
    final cubit = context.read<HomeCubit>();
    final done = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => MatchReviewScreen(match: m)));
    if (done == true) cubit.refresh();
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
            brandTitle: true,
            trailing: const HomeBell(),
          ),
        ),
        Expanded(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, s) {
              if (s.isLoading) return const SkeletonList();
              // الأقسام بتدخل واحدة ورا التانية (ظهور + طلوع خفيف)
              final sections = [
                _pointsHero(context, s),
                HomeAlerts(alerts: _alerts(context, s)),
                _nextMatch(context, s.nextMatch, s.openRound),
                HomeShortcuts(items: _shortcuts(context)),
                StarOfWeekCard(
                  star: s.star,
                  isFinal: s.weekFinal,
                  fromPrevious: s.starFromPrevious,
                  label: s.weekLabel,
                  liveStar: s.liveStar,
                  liveLabel: s.liveRound?.label ?? '',
                  onTap: (p, live) {
                    final w = live ? s.liveRound : s.starRound;
                    if (w == null) return;
                    showPlayerMatchesSheet(context, playerId: p.id, name: p.name, team: p.team, window: w);
                  },
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
}
