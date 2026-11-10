import 'package:flutter/material.dart';
import '../../manager/widgets/match_clock_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../manager/view/manager_match_screen.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/view/match_center_screen.dart';
import '../../matches/widgets/match_format.dart';
import '../cubit/tournament_cubit.dart';

part 'tournament_matches_tab_sections.dart';
part 'tournament_matches_tab_sections2.dart';

/// ماتشات البطولة بالدور (مجموعة A · ربع النهائي …): الضغط = صفحة الماتش. المنظّم: يحدد ميعاد كل ماتش
/// (القرعة بتعمل الماتشات من غير ميعاد) · إدارة الماتش · ولو تعادل في خروج المغلوب يختار الفايز (ضربات جزاء).
class TournamentMatchesTab extends StatelessWidget {
  const TournamentMatchesTab({super.key, required this.state, required this.runs});
  final TournamentState state;
  final bool runs;

  @override
  Widget build(BuildContext context) {
    if (state.matches.isEmpty) {
      return Center(
        child: Text('الماتشات بتتعمل بعد القرعة', style: AppText.body(13, color: AppColors.neutral600)),
      );
    }
    final byStage = <String, List<GameMatch>>{};
    for (final m in state.matches) {
      byStage.putIfAbsent(m.stage ?? 'ماتشات', () => []).add(m);
    }
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        if (runs && state.matches.any((m) => !m.timeSet))
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
            child: Text(
              'القرعة اتعملت — حدّد ميعاد كل ماتش من زرار «حدّد الميعاد». الماتش مبيظهرش للناس ولا بيتلعب '
              'غير لما ميعاده يتحدد، وبعدها تقدر تحط التشكيلة والأحداث عادي.',
              style: AppText.body(12, color: AppColors.accent700),
            ),
          ),
        for (final e in byStage.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(e.key, style: AppText.kicker(color: AppColors.accent, size: 11)),
          ),
          for (final m in e.value) _row(context, m),
        ],
      ],
    );
  }

  /// الفايز بالأخضر بعد الماتش.
  static Color _c(GameMatch m, String team) => m.isFinished && m.winner == team
      ? AppColors.accent
      : (m.isFinished && m.winner != null ? AppColors.neutral500 : AppColors.ink);
}
