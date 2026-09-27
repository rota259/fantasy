import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/models/player_gw_stat.dart';
import '../../players/data/stats_repository.dart';
import '../../week/data/week_window.dart';

/// إحصائيات اللاعب في الجولة (نقاط/امتلاك/دخول/خروج) + نقاطه في كل جولة.
class PlayerStatsSection extends StatelessWidget {
  const PlayerStatsSection({super.key, required this.playerId});

  final String playerId;

  Future<(WeekWindow, PlayerGwStat?, List<({int gw, int points})>)> _load(StatsRepository repo) async {
    final week = WeekWindow.current();
    final stats = await repo.windowStats(week);
    final hist = await repo.history(playerId);
    return (week, stats[playerId], hist);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<StatsRepository>();
    return FutureBuilder(
      future: _load(repo),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        final (week, s, hist) = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header('الجولة ${week.isFinal() ? '(النهائي)' : '(مباشر)'} · ${week.label}'),
            Row(
              children: [
                _tile('${s?.points ?? 0}', 'نقاط الجولة', AppColors.accent),
                _tile('${(s?.ownership ?? 0).toStringAsFixed(1)}%', 'الامتلاك', AppColors.ink),
                _tile('↗ ${s?.transfersIn ?? 0}', 'دخول', AppColors.accent),
                _tile('↘ ${s?.transfersOut ?? 0}', 'خروج', AppColors.danger),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Text(
                (s?.managers ?? 0) == 0
                    ? 'لسه محدش عمل تشكيلة في الجولة دي'
                    : 'اختاره ${s!.owners} من ${s.managers} عملوا تشكيلة في الجولة',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ),
            _header('نقاطه في كل جولة'),
            _bars(hist),
          ],
        );
      },
    );
  }

  Widget _header(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
    child: Text(t, style: AppText.h(13)),
  );

  Widget _tile(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
          left: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(value, style: AppText.h(17, color: color)),
          ),
          Text(label, style: AppText.body(9, color: AppColors.neutral700)),
        ],
      ),
    ),
  );

  Widget _bars(List<({int gw, int points})> hist) {
    if (hist.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Text('لسه ملعبش أي جولة', style: AppText.body(12, color: AppColors.neutral600)),
      );
    }
    final last = hist.length > 6 ? hist.sublist(hist.length - 6) : hist;
    final maxPts = last.map((h) => h.points).fold<int>(1, (a, b) => b > a ? b : a);
    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in last)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${h.points}', style: AppText.h(10)),
                    const SizedBox(height: 2),
                    Container(
                      height: 60 * (h.points <= 0 ? 0.04 : h.points / maxPts),
                      color: h == last.last ? AppColors.accent : AppColors.neutral400,
                    ),
                    const SizedBox(height: 4),
                    Text('GW${h.gw}', style: AppText.body(9, color: AppColors.neutral700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
