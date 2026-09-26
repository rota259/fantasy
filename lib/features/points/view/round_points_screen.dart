import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../pick/cubit/round_pick_cubit.dart';
import '../../pick/widgets/pick_pitch.dart';
import '../../players/data/models/player.dart';
import '../lineup_points.dart';
import '../points_engine.dart';
import '../cubit/my_points_cubit.dart';

/// تشكيلتي في جولة على الخماسي — جنب كل لاعب نقطه + تفصيل عمل إيه في ماتشات الجولة.
class RoundPointsScreen extends StatelessWidget {
  const RoundPointsScreen({super.key, required this.entry, required this.players});

  final RoundEntry entry;
  final Map<String, Player> players;

  @override
  Widget build(BuildContext context) {
    final w = entry.window;
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'الجولة · ${w.label}',
            subtitle:
                'نقطك: ${r.total}${entry.finalPoints.total != r.total ? ' (المعتمد ${entry.finalPoints.total})' : ''}',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                PickPitch(state: state, onSlotTap: (_) {}, onPlayerTap: (_) {}, pointsFor: pointsFor),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text('التفصيل', style: AppText.h(15)),
                ),
                for (final row in rows) _detail(row),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(PickPoints row) {
    final p = players[row.pick.playerId];
    final pos = p?.position ?? '';
    final tag = [
      if (row.pick.isCaptain) 'كابتن',
      if (row.pick.isVice) 'كابتن بديل',
      if (row.pick.status == 'bench') row.counted ? 'احتياطي — اتحسب بالكارت' : 'احتياطي — مش محسوب',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${p?.name ?? 'لاعب'}${tag.isEmpty ? '' : ' · $tag'}',
                  style: AppText.h(14, color: row.counted ? AppColors.ink : AppColors.neutral500),
                ),
              ),
              if (row.multiplier > 1 && row.counted)
                Text('${row.base} × ${row.multiplier} = ', style: AppText.body(12, color: AppColors.neutral700)),
              Text(
                '${row.counted ? row.total : row.base}',
                style: AppText.h(18, color: row.counted ? AppColors.accent : AppColors.neutral500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (row.events.isEmpty)
            Text('ملهوش أحداث في الجولة دي', style: AppText.body(11, color: AppColors.neutral600))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in row.events)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 2)),
                    child: Text(
                      '${PointsEngine.eventLabel(e.type)}${e.minute != null ? " ${e.minute}'" : ''} '
                      '(${_signed(PointsEngine.eventPoints(e.type, pos))})',
                      style: AppText.body(11),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static String _signed(int n) => n > 0 ? '+$n' : '$n';
}
