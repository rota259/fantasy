import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// شارة صعوبة الماتش (FDR 1–5): لونها بيتدرّج مع الصعوبة.
class FdrChip extends StatelessWidget {
  const FdrChip(this.level, {super.key, this.size = 26});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (level) {
      <= 2 => (AppColors.accent200, AppColors.accent800),
      3 || 4 => (AppColors.accent400, AppColors.white),
      _ => (AppColors.accent700, AppColors.white),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: bg,
      child: Text('$level', style: AppText.h(size * 0.46, color: fg)),
    );
  }
}
