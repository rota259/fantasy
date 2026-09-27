import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../pick/cubit/round_pick_cubit.dart';
import '../../pick/widgets/pick_pitch.dart';
import '../../players/data/models/player.dart';
import '../cubit/my_points_cubit.dart';
import '../play_status.dart';
import 'round_point_row.dart';

/// تشكيلتي في جولة على الخماسي — جنب كل لاعب نقطه + تفصيل عمل إيه في ماتشات الجولة.
/// [statusFor] (الجولة الشغّالة): مين لعب ومين بيلعب ومين لسه.
class RoundPointsBody extends StatelessWidget {
  const RoundPointsBody({super.key, required this.entry, required this.players, this.statusFor = const {}});

  final RoundEntry entry;
  final Map<String, Player> players;
  final Map<String, PlayStatus> statusFor;

  @override
  Widget build(BuildContext context) {
    final r = entry.points;
    String? cap, vice;
    for (final p in entry.picks) {
      if (p.isCaptain) cap = p.playerId;
      if (p.isVice) vice = p.playerId;
    }
    final state = RoundPickState(
      status: RoundPickStatus.ready,
      players: [
        for (final p in entry.picks)
          if (players[p.playerId] != null) players[p.playerId]!,
      ],
      sel: {for (final p in entry.picks) p.playerId: p.status},
      captainId: cap,
      viceId: vice,
    );
    // الأساسي: نقطه المحسوبة (بالمضاعفة). الاحتياطي: نقطه من غير ما تتحسب.
    final pointsFor = {for (final row in r.rows) row.pick.playerId: row.counted ? row.total : row.base};
    final viceDoubled = r.rows.any((x) => x.pick.isVice && x.multiplier > 1);
    final rows = [...r.rows]..sort((a, b) => (b.counted ? 1 : 0).compareTo(a.counted ? 1 : 0));
    int count(PlayState s) => statusFor.values.where((x) => x.state == s).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickPitch(state: state, onSlotTap: (_) {}, onPlayerTap: (_) {}, pointsFor: pointsFor),
        if (statusFor.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'لعبوا ${count(PlayState.played)} · بيلعبوا دلوقتي ${count(PlayState.live)} · لسه ${count(PlayState.upcoming)}',
              style: AppText.h(12, color: AppColors.neutral700),
            ),
          ),
        if (entry.chip != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '🃏 ${entry.chip!.label} — ${entry.chip!.description}',
              style: AppText.h(12, color: AppColors.info),
            ),
          ),
        if (viceDoubled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'الكابتن ملعبش ولا ماتش في الجولة — فالكابتن البديل خد المضاعفة',
              style: AppText.h(12, color: AppColors.accent),
            ),
          ),
        if (entry.finalPoints.total != r.total)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'المعتمد لحد دلوقتي ${entry.finalPoints.total} — الباقي بيتعتمد لما الماتشات تتأكد ⏳',
              style: AppText.body(11, color: AppColors.neutral700),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text('التفصيل', style: AppText.h(15)),
        ),
        for (final row in rows)
          RoundPointRow(row: row, player: players[row.pick.playerId], status: statusFor[row.pick.playerId]),
        const SizedBox(height: 20),
      ],
    );
  }
}
