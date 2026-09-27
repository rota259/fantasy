import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pentagon_avatar.dart';

/// أحرف أولى (بديل الصورة) جوه خماسي — نفس فريم الأفاتار في كل التطبيق.
class InitialsTile extends StatelessWidget {
  const InitialsTile(this.text, {super.key, this.size = 34, this.background, this.color, this.photoUrl});

  final String text;
  final double size;
  final Color? background; // الافتراضي neutral200
  final Color? color; // الافتراضي neutral800
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return PentagonAvatar(
      initials: text,
      photoUrl: photoUrl,
      size: size,
      background: background ?? AppColors.neutral200,
      color: color ?? AppColors.neutral800,
    );
  }
}
