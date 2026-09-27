import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../seasons/data/season.dart';

/// اختيار الموسم (أو "كل المواسم") — شريط أفقي.
class SeasonChips extends StatelessWidget {
  const SeasonChips({super.key, required this.seasons, required this.selected, required this.onSelect});

  final List<Season> seasons;
  final Season? selected; // null = كل المواسم
  final ValueChanged<Season?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final s in seasons)
            _chip(s.isCurrent() ? '${s.name} · الحالي' : s.name, selected?.id == s.id, () => onSelect(s)),
          _chip('كل المواسم', selected == null, () => onSelect(null)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 6),
    child: Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? AppColors.accent : AppColors.card,
          borderRadius: AppRadius.lg,
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
        ),
        child: Text(label, style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
      ),
    ),
  );
}
