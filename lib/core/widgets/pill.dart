import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// شارة صغيرة (pill) — مملوءة أو بحدود. صفر انحناء زي الديزاين.
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.background,
    this.color = AppColors.ink,
    this.border,
    this.size = 10,
  });

  /// نسخة مملوءة بالأخضر ونص أبيض.
  const Pill.accent(this.text, {super.key, this.size = 10})
      : background = AppColors.accent,
        color = AppColors.white,
        border = null;

  final String text;
  final Color? background;
  final Color color;
  final Color? border;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        text,
        style: AppText.h(size, color: color, spacingEm: 0.04),
      ),
    );
  }
}
