import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../chips/data/chips_repository.dart';
import '../../events/data/events_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../pick/data/picks_repository.dart';
import '../../players/data/players_repository.dart';
import '../cubit/my_points_cubit.dart';
import 'round_points_screen.dart';

/// نقطك: كل جولة عملت فيها تشكيلة وجبت فيها كام + بونص التوقعات — تدوس تشوف الخماسي بالتفصيل.
class MyPointsScreen extends StatelessWidget {
  const MyPointsScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => MyPointsCubit(
        userId: userId,
        picks: c.read<PicksRepository>(),
        matches: c.read<MatchesRepository>(),
        events: c.read<EventsRepository>(),
        players: c.read<PlayersRepository>(),
        chips: c.read<ChipsRepository>(),
        challenge: c.read<ChallengeRepository>(),
      )..load(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const StatusArea(),
            Masthead(title: 'نقطك', subtitle: 'MY POINTS', onBack: () => Navigator.pop(context)),
            Expanded(child: BlocBuilder<MyPointsCubit, MyPointsState>(builder: _body)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MyPointsState s) {
    if (s.status == MyPointsStatus.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (s.status == MyPointsStatus.error) {
      return Center(
        child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
      );
    }
    if (s.entries.isEmpty && s.bonuses.isEmpty) {
      return Center(
        child: Text('لسه معملتش تشكيلة لأي جولة', style: AppText.body(13, color: AppColors.neutral600)),
      );
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: AppColors.black,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نقطك المعتمدة من ${s.entries.length} جولة${s.bonuses.isEmpty ? '' : ' + بونص التوقعات'}',
                      style: AppText.h(13, color: AppColors.white.withValues(alpha: 0.7)),
                    ),
                    if (s.provisional != 0)
                      Text(
                        'و ${s.provisional} مبدئية ⏳ — بتدخل لما الماتش يتأكد',
                        style: AppText.body(11, color: AppColors.accent400),
                      ),
                  ],
                ),
              ),
              Text('${s.total}', style: AppText.h(40, color: AppColors.white)),
            ],
          ),
        ),
        for (final e in s.entries) _round(context, e, s),
        for (final m in s.bonuses)
          _line(
            '🎯 توقّعت ${m.teamA} ${m.scoreText} ${m.teamB} صح',
            'تحدّي الجولة',
            '+${MyPointsState.predictionBonus}',
          ),
      ],
    );
  }

  Widget _round(BuildContext context, RoundEntry e, MyPointsState s) {
    final w = e.window;
    final status = w.isFinal() ? 'خلصت' : (w.hasStarted() ? 'شغّالة' : 'لسه');
    final pending = e.points.total != e.finalPoints.total ? ' · مبدئي ⏳' : '';
    final chip = e.chip == null ? '' : ' · 🃏 ${e.chip!.label}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoundPointsScreen(entry: e, players: s.players),
        ),
      ),
      child: _line('الجولة · ${w.label}', '$status$pending$chip', '${e.points.total}', arrow: true),
    );
  }

  Widget _line(String title, String sub, String pts, {bool arrow = false}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h(15)),
              Text(sub, style: AppText.body(11, color: AppColors.neutral700)),
            ],
          ),
        ),
        Text(pts, style: AppText.h(24, color: AppColors.accent)),
        if (arrow) ...[const SizedBox(width: 6), Text('›', style: AppText.body(18, color: AppColors.neutral600))],
      ],
    ),
  );
}
