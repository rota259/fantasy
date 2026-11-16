import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/motion.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/view/match_center_screen.dart';
import '../../matches/widgets/match_format.dart';
import '../../players/data/models/player_match.dart';
import '../../players/data/stats_repository.dart';

/// بروفايل اللاعب: ماتشاته (الأحدث الأول) — الفريقين والنتيجة وفريقه، أساسي ولا احتياطي، وعمل إيه ونقطه.
/// الضغطة على ماتش بتفتح صفحته.
class PlayerMatchesSection extends StatefulWidget {
  const PlayerMatchesSection({super.key, required this.playerId});
  final String playerId;

  @override
  State<PlayerMatchesSection> createState() => _PlayerMatchesSectionState();
}

class _PlayerMatchesSectionState extends State<PlayerMatchesSection> {
  late Future<List<PlayerMatch>> _future = _load();

  Future<List<PlayerMatch>> _load() =>
      context.read<StatsRepository>().matches(widget.playerId).catchError((_) => const <PlayerMatch>[]);

  @override
  void didUpdateWidget(PlayerMatchesSection old) {
    super.didUpdateWidget(old);
    if (old.playerId != widget.playerId) _future = _load();
  }

  Future<void> _open(PlayerMatch pm) async {
    final nav = Navigator.of(context);
    final m = (await context.read<MatchesRepository>().fetchByIds([pm.matchId])).firstOrNull;
    if (m != null) await nav.push(MaterialPageRoute(builder: (_) => MatchCenterScreen(match: m)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PlayerMatch>>(
    future: _future,
    builder: (context, snap) {
      final list = snap.data;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Text('ماتشاته', style: AppText.h(13)),
          ),
          if (list == null)
            const Padding(padding: EdgeInsets.all(16), child: SkeletonList(rows: 2))
          else if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Text('لسه ملعبش ماتشات', style: AppText.body(12, color: AppColors.neutral600)),
            )
          else
            for (final pm in list) _card(pm),
        ],
      );
    },
  );

  Widget _card(PlayerMatch pm) {
    final res = pm.result;
    final state = !pm.finished ? 'لايف' : (pm.approved ? null : 'نقط مبدئية');
    Widget teamText(String t) => Expanded(
      child: Text(
        t,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: AppText.h(13, color: t == pm.team ? AppColors.accent : AppColors.ink),
      ),
    );
    return Pressable(
      onTap: () => _open(pm),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.all(12),
        decoration: AppDecor.tile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${arabicWeekday(pm.dateTime)} ${pm.dateTime.day}/${pm.dateTime.month}'
                    '${pm.venue == null ? '' : ' · ${pm.venue}'}',
                    style: AppText.body(11, color: AppColors.neutral700),
                  ),
                ),
                Text('${pm.points} نقطة', style: AppText.h(14, color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                teamText(pm.teamA),
                Text(pm.score, textDirection: TextDirection.ltr, style: AppText.h(18)),
                teamText(pm.teamB),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              [pm.starter ? 'أساسي' : 'احتياطي', ?res, ?state].join(' · '),
              textAlign: TextAlign.center,
              style: AppText.body(11, color: AppColors.neutral700),
            ),
            if (pm.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [for (final i in pm.items) _chip(i)],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(({String label, int count, int points}) i) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: i.points < 0 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.accent100,
      borderRadius: AppRadius.sm,
    ),
    child: Text(
      '${i.label}${i.count > 1 ? ' ×${i.count}' : ''} (${i.points > 0 ? '+' : ''}${i.points})',
      style: AppText.body(11, color: i.points < 0 ? AppColors.danger : AppColors.accent800),
    ),
  );
}
