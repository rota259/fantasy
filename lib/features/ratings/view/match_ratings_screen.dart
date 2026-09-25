import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../manager/data/lineup_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../players/data/players_repository.dart';
import '../cubit/match_ratings_cubit.dart';
import '../data/ratings_repository.dart';
import '../widgets/rating_row.dart';

/// تقييم الجمهور بعد الماتش (٢٤ ساعة): الأعلى تقييمًا = رجل المباراة ويكسب +٣.
class MatchRatingsScreen extends StatelessWidget {
  const MatchRatingsScreen({super.key, required this.match, required this.userId});

  final GameMatch match;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => MatchRatingsCubit(
        c.read<RatingsRepository>(),
        c.read<LineupRepository>(),
        c.read<PlayersRepository>(),
        match,
        userId,
      )..load(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const StatusArea(),
            Masthead(
              title: '${match.teamA} ${match.scoreText} ${match.teamB}',
              subtitle: 'قيّم اللاعيبة · FAN RATINGS',
              onBack: () => Navigator.pop(context),
            ),
            _banner(),
            Expanded(child: BlocBuilder<MatchRatingsCubit, MatchRatingsState>(builder: _list)),
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    final end = match.finishedAt?.add(GameMatch.ratingWindow);
    final text = match.ratingOpen && end != null
        ? 'قيّم كل لاعب من ١ لـ ١٠ — التقييم بيقفل ${arabicWeekday(end)} ${arabicTime(end)}، والأعلى ياخد رجل المباراة (+٣)'
        : 'التقييم اتقفل — دي النتيجة النهائية';
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(text, style: AppText.h(11, color: AppColors.accent400)),
    );
  }

  Widget _list(BuildContext context, MatchRatingsState s) {
    if (s.loading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    if (s.players.isEmpty) {
      return Center(
        child: Text('مفيش تشكيلة للماتش ده', style: AppText.body(13, color: AppColors.neutral600)),
      );
    }
    final cubit = context.read<MatchRatingsCubit>();
    final leader = match.motmPlayerId ?? s.leaderId;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final p in s.players)
          RatingRow(
            player: p,
            rating: s.ratings[p.id],
            leader: p.id == leader,
            onRate: match.ratingOpen
                ? (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final err = await cubit.rate(p.id, v);
                    if (err != null) {
                      messenger.showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.danger));
                    }
                  }
                : null,
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
