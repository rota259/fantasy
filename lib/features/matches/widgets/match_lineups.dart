import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../cubit/match_center_cubit.dart';
import '../match_live.dart';

/// تشكيلة الفريقين: الأساسي والاحتياطي — اللي طلع تبديل أو خد أحمر بيبان باهت.
class MatchLineups extends StatelessWidget {
  const MatchLineups({super.key, required this.state});
  final MatchCenterState state;

  @override
  Widget build(BuildContext context) {
    final teams = state.match.teams;
    if (state.lineup.isEmpty || teams.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('التشكيلة لسه منزلتش', style: AppText.body(12, color: AppColors.neutral600)),
      );
    }
    final on = MatchLive.onPitch(state.lineup, state.events);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Text('التشكيلة', style: AppText.h(15)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _team(teams[0], on)),
              const SizedBox(width: 12),
              Expanded(child: _team(teams[1], on)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _team(String team, Set<String> on) {
    List<String> ids(String st) => [
      for (final e in state.lineup.entries)
        if (e.value == st && state.teamOf(e.key) == team) e.key,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(team, style: AppText.h(13, color: AppColors.accent)),
        const SizedBox(height: 4),
        for (final id in ids('starting')) _name(id, on.contains(id)),
        const SizedBox(height: 6),
        Text('احتياطي', style: AppText.kicker()),
        for (final id in ids('bench')) _name(id, on.contains(id)),
      ],
    );
  }

  Widget _name(String id, bool playing) {
    final p = state.players[id];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${playing ? '● ' : ''}${p?.name ?? '—'}${p?.position == 'GK' ? ' 🧤' : ''}',
        style: AppText.body(12, color: playing ? AppColors.ink : AppColors.neutral500),
      ),
    );
  }
}
