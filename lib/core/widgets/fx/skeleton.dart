import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../motion.dart';

/// لمعة بتعدّي على الشكل الرمادي (بدل الدايرة اللي بتلف وقت التحميل).
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.neutral200;
    final hi = AppColors.card;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment(-1.6 + 3.2 * _c.value, 0),
          end: Alignment(-0.6 + 3.2 * _c.value, 0),
          colors: [base, hi, base],
        ).createShader(r),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// شكل قايمة كروت بتحمّل: كروت رمادي بنفس شكل الصفوف + لمعة.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 6});
  final int rows;

  @override
  Widget build(BuildContext context) {
    final block = AppColors.neutral200;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: block, borderRadius: AppRadius.sm),
    );
    return Shimmer(
      child: ListView(
        shrinkWrap: true, // ينفع جوه قايمة تانية
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 14),
        children: [
          for (var i = 0; i < rows; i++)
            Container(
              margin: AppDecor.tileMargin,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: block, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [bar(140.0 - (i % 3) * 20, 12), const SizedBox(height: 8), bar(90, 10)],
                    ),
                  ),
                  bar(28, 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
