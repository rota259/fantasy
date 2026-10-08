import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/blink_dot.dart';
import '../data/models/game_match.dart';
import 'match_format.dart';
import '../../../core/widgets/fx/flips.dart';

/// لوحة النتيجة: الفريقين والنتيجة (بتعدّ لايف مع كل جول) وحالة الماتش.
class MatchScoreboard extends StatelessWidget {
  const MatchScoreboard({super.key, required this.match, required this.a, required this.b});

  final GameMatch match;
  final int a;
  final int b;

  @override
  Widget build(BuildContext context) {
    final m = match;
    final live = m.hasStarted && !m.isFinished;
    final notYet = !m.hasStarted && !m.isFinished;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.black, AppColors.night]),
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _team(m.teamA)),
              if (notYet)
                Text(arabicTime(m.dateTime), style: AppText.h(22, color: AppColors.white))
              else ...[
                FlipNumber(
                  value: a,
                  style: AppText.h(46, color: AppColors.white, height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('-', style: AppText.h(30, color: AppColors.white.withValues(alpha: 0.6))),
                ),
                FlipNumber(
                  value: b,
                  style: AppText.h(46, color: AppColors.white, height: 1),
                ),
              ],
              Expanded(child: _team(m.teamB)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (live) ...[BlinkDot(color: AppColors.danger), const SizedBox(width: 6)],
              Text(
                _status(m, live, notYet),
                style: AppText.h(11, color: live ? AppColors.danger : AppColors.accent400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _status(GameMatch m, bool live, bool notYet) {
    if (live) return 'لايف دلوقتي';
    if (notYet) return '${arabicWeekday(m.dateTime)} ${m.dateTime.day}/${m.dateTime.month}';
    if (m.isVoid) return 'الماتش اتلغى';
    return m.isApproved ? 'خلص · النتيجة معتمدة ✓' : 'خلص · مستني تأكيد اللاعيبة ⏳';
  }

  Widget _team(String t) => Text(
    t,
    textAlign: TextAlign.center,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: AppText.h(14, color: AppColors.white),
  );
}
