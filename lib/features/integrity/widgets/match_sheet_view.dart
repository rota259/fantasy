import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../events/data/models/match_event.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../points/points_engine.dart';
import '../data/models/match_flags.dart';

/// ورقة الماتش: النتيجة + علامات الغرابة + أحداث كل فريق (للتأكيد والمراجعة).
class MatchSheetView extends StatelessWidget {
  const MatchSheetView({super.key, required this.match, required this.events, required this.players});

  final GameMatch match;
  final List<MatchEvent> events;
  final Map<String, Player> players;

  @override
  Widget build(BuildContext context) {
    final m = match;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            children: [
              Expanded(child: _team(m.teamA)),
              Text(m.scoreText.isEmpty ? '—' : m.scoreText, style: AppText.h(34, color: AppColors.white)),
              Expanded(child: _team(m.teamB)),
            ],
          ),
        ),
        for (final f in m.flags)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.bronze, borderRadius: AppRadius.md),
            child: Text('⚠️ ${MatchFlags.label(f)}', style: AppText.h(12, color: AppColors.white)),
          ),
        for (final t in m.teams) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
            child: Text(t, style: AppText.kicker(color: AppColors.accent)),
          ),
          ..._teamEvents(t),
        ],
      ],
    );
  }

  Widget _team(String name) => Text(
    name,
    textAlign: TextAlign.center,
    maxLines: 2,
    style: AppText.h(14, color: AppColors.white),
  );

  List<Widget> _teamEvents(String team) {
    final list = [
      for (final e in events)
        if (players[e.playerId]?.team == team) e,
    ]..sort((a, b) => (a.minute ?? 999).compareTo(b.minute ?? 999));
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text('مفيش أحداث', style: AppText.body(12, color: AppColors.neutral600)),
        ),
      ];
    }
    return [
      for (final e in list)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(e.minute == null ? '' : "${e.minute}'", style: AppText.h(12, color: AppColors.neutral700)),
              ),
              Expanded(child: Text(players[e.playerId]?.name ?? '—', style: AppText.h(13))),
              Text(PointsEngine.eventLabel(e.type), style: AppText.body(12, color: AppColors.neutral700)),
            ],
          ),
        ),
    ];
  }
}
