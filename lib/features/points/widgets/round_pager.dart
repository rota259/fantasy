import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../cubit/my_points_cubit.dart';

/// التنقّل بين الجولات: ‹ الجولة N · التاريخ · النقط ›.
class RoundPager extends StatelessWidget {
  const RoundPager({super.key, required this.entry, this.number, this.onPrev, this.onNext});

  final RoundEntry entry;
  final int? number; // رقم الجولة جوه الموسم (null = الجولة اللي بتتلعب)
  final VoidCallback? onPrev; // الأقدم
  final VoidCallback? onNext; // الأحدث

  @override
  Widget build(BuildContext context) {
    final w = entry.window;
    final status = w.isFinal() ? 'خلصت' : (w.hasStarted() ? 'شغّالة ⚽' : 'لسه');
    final chip = entry.chip == null ? '' : ' · 🃏 ${entry.chip!.label}';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
      child: Row(
        children: [
          _arrow('›', onPrev), // RTL: السهم اللي يمين = اللي قبلها
          Expanded(
            child: SoftSwitcher(
              child: Column(
                key: ValueKey(w.cutoff),
                children: [
                  Text(
                    number == null ? 'الجولة اللي بتتلعب' : 'الجولة $number',
                    style: AppText.h(15, color: AppColors.white),
                  ),
                  Text(
                    '${w.label} · $status$chip',
                    textAlign: TextAlign.center,
                    style: AppText.body(10, color: AppColors.white.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 4),
                  CountUp(
                    value: entry.points.total,
                    style: AppText.h(34, color: AppColors.accent400),
                  ),
                ],
              ),
            ),
          ),
          _arrow('‹', onNext),
        ],
      ),
    );
  }

  Widget _arrow(String t, VoidCallback? onTap) => Pressable(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        t,
        style: AppText.h(28, color: onTap == null ? AppColors.white.withValues(alpha: 0.2) : AppColors.white),
      ),
    ),
  );
}
