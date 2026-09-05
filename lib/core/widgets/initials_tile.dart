import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// مربّع أحرف أولى (بديل صورة اللاعب) — صفر انحناء.
class InitialsTile extends StatelessWidget {
  const InitialsTile(
    this.text, {
    super.key,
    this.size = 34,
    this.background = AppColors.neutral200,
    this.color = AppColors.neutral800,
    this.fontSize = 12,
  });

  final String text;
  final double size;
  final Color background;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: background,
      child: Text(text, style: AppText.h(fontSize, color: color)),
    );
  }
}
