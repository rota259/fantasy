import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/availability.dart';

/// شارة حالة اللاعب المرئية:
/// جاهز ⚡ (أخضر) · مصاب ✚ (أحمر) · مشكوك ؟ (أصفر) · موقوف 🟥 كارت أحمر.
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge(this.availability, {super.key, this.size = 20});

  final String availability;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Availability.color(availability);
    return Container(width: size, height: size, alignment: Alignment.center, color: color, child: _inner(color));
  }

  Widget _inner(Color color) {
    final s = size * 0.62;
    switch (availability) {
      case Availability.injured:
        return Icon(Icons.add, size: s, color: AppColors.white); // صليب أحمر
      case Availability.doubtful:
        return Text('؟', style: AppText.h(size * 0.55, color: AppColors.white));
      case Availability.suspended:
        // كارت أحمر: مستطيل أبيض صغير جوه المربّع الأحمر
        return Container(width: size * 0.3, height: size * 0.55, color: AppColors.white);
      default:
        return Icon(Icons.bolt, size: s, color: AppColors.white); // جاهز ⚡
    }
  }
}
