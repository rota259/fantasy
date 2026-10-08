import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/effects.dart';

/// شارة نقط اللاعب تحت صورته — ولما النقط تزيد (جول لايف مثلًا) بيطلع فوقها «+٥» ويطير ويختفي.
class PointsPop extends StatefulWidget {
  const PointsPop({super.key, required this.value});
  final int value;

  @override
  State<PointsPop> createState() => _PointsPopState();
}

class _PointsPopState extends State<PointsPop> {
  int? _gain;
  int _shot = 0; // كل زيادة = طلقة جديدة

  @override
  void didUpdateWidget(PointsPop old) {
    super.didUpdateWidget(old);
    final d = widget.value - old.value;
    if (d != 0) {
      _gain = d;
      _shot++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.value;
    final g = _gain;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: n > 0 ? AppColors.accent : (n < 0 ? AppColors.danger : AppColors.neutral600),
            borderRadius: AppRadius.sm,
          ),
          child: Text('$n', style: AppText.h(11, color: AppColors.white)),
        ),
        if (g != null)
          Positioned(
            top: -16,
            child: FloatUp(
              key: ValueKey(_shot),
              child: Text(
                g > 0 ? '+$g' : '$g',
                style: AppText.h(16, color: g > 0 ? const Color(0xFFF2C14E) : AppColors.danger),
              ),
            ),
          ),
      ],
    );
  }
}
