import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/brand_logo.dart';

/// لوجو الاسبلاش + الاسم — في الآخر بيبقوا نفس شكل الهوية بالظبط (اللوجو يمين والاسم شماله):
///   ١) الصديري بيتمايل من رقبته زي ما يكون متعلّق وبيهدى.
///   ٢) رقم 5 بيترسم زي خط الجير على الملعب.
///   ٣) نقطة السنتر بتنطّ في مكانها.
///   ٤) اسم «الخماسي» بيطلع جنبه.
/// [animation] من 0 لـ 1 على طول الاسبلاش.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, required this.animation, this.size = 96});

  final Animation<double> animation;
  final double size; // ارتفاع اللوجو

  static double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final appear = Curves.easeOut.transform(_seg(t, 0, 0.12));
        // تمايل بيخفت: ±٦° وبيهدى على ٠
        final sway = math.sin(t * math.pi * 3.2) * 0.10 * (1 - Curves.easeOut.transform(_seg(t, 0, 0.62)));
        final draw = const Cubic(.5, 0, .3, 1).transform(_seg(t, 0.12, 0.48));
        final spot = Curves.easeOutBack.transform(_seg(t, 0.48, 0.60));
        final name = Curves.easeOutCubic.transform(_seg(t, 0.58, 0.80));
        return Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Opacity(
              opacity: appear,
              child: BibLogo(size: size, draw: draw, spotScale: spot, angle: sway),
            ),
            // الاسم بيفتح مكانه ويطلع (فاللوجو بيتزحزح يمين بنعومة)
            ClipRect(
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: name,
                child: Opacity(
                  opacity: name,
                  child: Padding(
                    padding: EdgeInsets.only(right: size * 0.22),
                    child: BrandWordmark(size: size * 0.78),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
