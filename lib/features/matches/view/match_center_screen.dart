import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../events/data/events_repository.dart';
import '../../manager/data/lineup_repository.dart';
import '../../players/data/players_repository.dart';
import '../../ratings/view/match_ratings_screen.dart';
import '../cubit/match_center_cubit.dart';
import '../data/matches_repository.dart';
import '../data/models/game_match.dart';
import '../widgets/match_lineups.dart';
import '../widgets/match_scoreboard.dart';
import '../widgets/match_summary.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../widgets/match_story_card.dart';
import '../../../core/share/story_share_sheet.dart';

/// صفحة الماتش لأي يوزر: النتيجة لايف + ملخص الأحداث المهمة تحتها + كل الأحداث + التشكيلتين.
class MatchCenterScreen extends StatelessWidget {
  const MatchCenterScreen({super.key, required this.match});
  final GameMatch match;

  static Future<void> open(BuildContext context, GameMatch m) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MatchCenterScreen(match: m)));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => MatchCenterCubit(
        c.read<MatchesRepository>(),
        c.read<EventsRepository>(),
        c.read<LineupRepository>(),
        c.read<PlayersRepository>(),
        match,
      )..load(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const StatusArea(),
            Masthead(
              title: '${match.teamA} ضد ${match.teamB}',
              subtitle: 'MATCH',
              onBack: () => Navigator.pop(context),
              // ورقة الماتش للشير (المدير ينزّلها على صفحة ملعبه)
              trailing: Builder(
                builder: (c) => IconButton(
                  icon: Icon(Icons.ios_share, color: AppColors.white),
                  onPressed: () {
                    final s = c.read<MatchCenterCubit>().state;
                    showStoryShare(
                      c,
                      card: MatchStoryCard(state: s, refCode: c.read<AuthCubit>().state.user?.refCode),
                      text:
                          '${s.match.teamA} ${s.match.scoreA ?? 0} - ${s.match.scoreB ?? 0} ${s.match.teamB} ⚽ — تابع ماتشات منطقتك في الخماسي',
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<MatchCenterCubit, MatchCenterState>(
                builder: (context, s) {
                  if (s.loading) return const SkeletonList();
                  final m = s.match;
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      MatchScoreboard(match: m, a: m.scoreA ?? 0, b: m.scoreB ?? 0),
                      MatchSummary(state: s),
                      if (m.ratingOpen || m.motmDone) _rate(context, m),
                      MatchTimeline(state: s),
                      MatchLineups(state: s),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rate(BuildContext context, GameMatch m) {
    final uid = context.read<AuthCubit>().state.user?.id;
    if (uid == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Pressable(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MatchRatingsScreen(match: m, userId: uid),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(11),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
          child: Text(
            m.ratingOpen ? '⭐ قيّم اللاعيبة واختار رجل المباراة' : '⭐ رجل المباراة والتقييمات',
            style: AppText.h(13, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
