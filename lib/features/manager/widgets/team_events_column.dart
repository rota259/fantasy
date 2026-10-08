import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../events/data/models/match_event.dart';
import '../../players/data/models/player.dart';
import '../../points/points_engine.dart';

/// نص الشاشة لفريق واحد: اللي في الملعب بس — تدوس على لاعب يتسجّل له الحدث المختار.
/// جنب كل لاعب ملخص اللي عمله (⚽٢ 🎯١ 🟨).
class TeamEventsColumn extends StatelessWidget {
  const TeamEventsColumn({
    super.key,
    required this.team,
    required this.goals,
    required this.players,
    required this.events,
    required this.onTap,
  });

  final String team;
  final int goals;
  final List<Player> players; // اللي في الملعب دلوقتي
  final List<MatchEvent> events;
  final void Function(Player p) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  team,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h(12, color: AppColors.white),
                ),
              ),
              CountUp(
                value: goals,
                style: AppText.h(18, color: AppColors.accent400),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (players.isEmpty)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text('مفيش حد في الملعب', style: AppText.body(11, color: AppColors.neutral600)),
          ),
        for (final p in players) _tile(p),
      ],
    );
  }

  Widget _tile(Player p) {
    final mine = events.where((e) => e.playerId == p.id && e.type != 'sub').toList();
    final counts = <String, int>{};
    for (final e in mine) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }
    final summary = [
      for (final c in counts.entries) '${PointsEngine.eventIcon(c.key)}${c.value > 1 ? c.value : ''}',
    ].join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Pressable(
        onTap: () => onTap(p),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p.name}${p.position == 'GK' ? ' 🧤' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.h(12),
              ),
              if (summary.isNotEmpty) Text(summary, style: AppText.body(11)),
            ],
          ),
        ),
      ),
    );
  }
}

/// التبديل: مين ينزل مكان [out] من احتياطي فريقه اللي لسه منزلش.
Future<Player?> showSubSheet(BuildContext context, Player out, List<Player> bench) {
  return showModalBottomSheet<Player>(
    context: context,
    backgroundColor: AppColors.bg,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('🔁 مين ينزل مكان ${out.name}؟', style: AppText.h(15)),
          ),
          if (bench.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text('مفيش احتياطي فاضل في ${out.team}', style: AppText.body(13, color: AppColors.neutral600)),
            ),
          for (final p in bench)
            ListTile(
              title: Text(p.name, style: AppText.h(14)),
              subtitle: Text(p.positionAr, style: AppText.body(11, color: AppColors.neutral700)),
              trailing: Text('نزّله ›', style: AppText.h(12, color: AppColors.accent)),
              onTap: () => Navigator.pop(c, p),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
