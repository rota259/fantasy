import 'package:flutter/material.dart';

import '../../../core/widgets/kha_logo.dart';

/// لوجو الاسبلاش: حرف الخاء ثابت، ونقطته (الكورة) بتنزل من فوق وتنطّ نطّتين وهي بتلف — وبعدها تثبت.
/// [animation] من 0 لـ 1 على طول الاسبلاش: الكورة بتتحرك في أول ٦٥٪ والباقي ثابت.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, required this.animation, this.size = 172});

  final Animation<double> animation;
  final double size;

  /// ارتفاع الكورة فوق مكانها (بوحدات اللوجو) عند وقت [t]: نزول ← نطّة عالية ← نطّة صغيرة ← ثبات.
  static double _height(double t) {
    double arc(double a, double b, double peak) {
      final x = ((t - a) / (b - a)).clamp(0.0, 1.0);
      return peak * 4 * x * (1 - x); // قوس نطّة
    }

    if (t < 0.30) return 46 * (1 - Curves.easeIn.transform(t / 0.30)); // نازلة من فوق
    if (t < 0.48) return arc(0.30, 0.48, 13);
    if (t < 0.60) return arc(0.48, 0.60, 5);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final letterIn = Curves.easeOut.transform((t / 0.18).clamp(0.0, 1.0));
        // الكورة بتتفلطح سنّة لحظة ما تلمس الحرف
        final squash = (t > 0.28 && t < 0.34) || (t > 0.47 && t < 0.50) ? 0.94 : 1.0;
        return Opacity(
          opacity: letterIn,
          child: Transform.scale(
            scale: 0.92 + 0.08 * letterIn,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(1, squash, 1),
              child: KhaLogo(
                size: size,
                ballDy: -_height(t),
                ballTurns: 0.55 * Curves.easeOut.transform((t / 0.60).clamp(0.0, 1.0)),
                ballOpacity: (t / 0.10).clamp(0.0, 1.0),
              ),
            ),
          ),
        );
      },
    );
  }
}
