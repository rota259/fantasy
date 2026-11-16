import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../manager/data/lineup_repository.dart';
import '../../manager/data/models/lineup.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import 'captain_lineup_sheet.dart';

/// (كابتن) ماتشات فريقي الجاية — لكل ماتش: ابعت التشكيلة للمدير (وحالتها: اتبعتت · المدير طبّقها).
class CaptainMatchesCard extends StatefulWidget {
  const CaptainMatchesCard({super.key, required this.team});
  final String team;

  @override
  State<CaptainMatchesCard> createState() => _CaptainMatchesCardState();
}

class _CaptainMatchesCardState extends State<CaptainMatchesCard> {
  late Future<List<(GameMatch, TeamLineup?)>> _future = _load();

  Future<List<(GameMatch, TeamLineup?)>> _load() async {
    final lineups = context.read<LineupRepository>();
    final list = await context.read<MatchesRepository>().upcomingForTeam(widget.team);
    return [
      for (final m in list.where((m) => m.timeSet))
        (
          m,
          (await lineups.teamLineups(m.id).catchError((_) => const <TeamLineup>[]))
              .where((l) => l.team == widget.team)
              .firstOrNull,
        ),
    ];
  }

  Future<void> _open(GameMatch m) async {
    final sent = await showCaptainLineupSheet(context, m, widget.team);
    if (sent == true && mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<(GameMatch, TeamLineup?)>>(
    future: _future,
    builder: (context, snap) {
      final list = snap.data ?? const [];
      if (list.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: AppDecor.tile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ماتشات فريقك الجاية', style: AppText.h(15)),
            for (final (m, l) in list)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(13)),
                          Text(
                            '${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)}'
                            '${l == null ? '' : (l.applied ? ' · ✓ المدير نزّلها' : ' · ⏳ اتبعتت للمدير')}',
                            style: AppText.body(
                              11,
                              color: l?.applied == true ? AppColors.accent : AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(onPressed: () => _open(m), child: Text(l == null ? 'ابعت التشكيلة' : 'عدّلها')),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}
