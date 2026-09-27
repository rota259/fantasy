import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/widgets/match_format.dart';
import '../../week/data/week_window.dart';
import '../cubit/round_pick_cubit.dart';
import '../../../core/widgets/motion.dart';

/// شريط الديدلاين فوق التشكيلة.
class DeadlineBar extends StatelessWidget {
  const DeadlineBar({super.key, required this.window, required this.wildcard});

  final WeekWindow window;
  final bool wildcard;

  @override
  Widget build(BuildContext context) {
    final String text;
    var color = AppColors.accent400;
    if (!window.isLocked()) {
      text = 'بتقفل ${arabicWeekday(window.deadline)} ${arabicTime(window.deadline)} · ${window.label}';
    } else if (window.hasStarted()) {
      text = 'الجولة بدأت — التشكيلة اتقفلت';
      color = AppColors.neutral400;
    } else if (wildcard) {
      text = '🃏 الوايلد كارد شغّال — عدّل لحد ${arabicTime(window.start)}';
    } else {
      text = 'التشكيلة اتقفلت — الجولة بتبدأ ${arabicTime(window.start)}';
      color = AppColors.neutral400;
    }
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: Text(text, style: AppText.h(11, color: color)),
    );
  }
}

/// أساسي ٣/٥ · احتياطي ١/٢ · كابتن ✓ · بديل ✗
class PickCounts extends StatelessWidget {
  const PickCounts({super.key, required this.state});
  final RoundPickState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Wrap(
        spacing: 14,
        children: [
          Text('أساسي ${s.startingCount}/5', style: AppText.h(13, color: AppColors.accent)),
          Text('احتياطي ${s.benchCount}/2', style: AppText.h(13)),
          Text('كابتن ${s.captainId == null ? '✗' : '✓'}', style: AppText.h(13)),
          Text('بديل ${s.viceId == null ? '✗' : '✓'}', style: AppText.h(13)),
        ],
      ),
    );
  }
}

/// شريط ملوّن برسالة.
class PickBanner extends StatelessWidget {
  const PickBanner({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.md),
    child: Text(text, style: AppText.h(12, color: AppColors.white)),
  );
}

/// زرار الحفظ تحت.
class SaveBar extends StatelessWidget {
  const SaveBar({super.key, required this.onSave});
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.black,
    padding: const EdgeInsets.all(12),
    child: SafeArea(
      top: false,
      child: Pressable(
        onTap: onSave,
        child: Container(
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          child: Text('احفظ تشكيلة الجولة', style: AppText.h(14, color: AppColors.white)),
        ),
      ),
    ),
  );
}
