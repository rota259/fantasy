import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// لوجو الاسبلاش: مضلّع بيترسم + نقط بتظهر على الرؤوس + رقم ٥ بيكبر.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, required this.animation, this.size = 172});

  final Animation<double> animation;
  final double size;

  static const List<Offset> _pts = [
    Offset(50, 16), Offset(82.3, 39.5), Offset(70, 77.5),
    Offset(30, 77.5), Offset(17.7, 39.5),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final draw = Curves.easeInOut.transform((t / 0.5).clamp(0, 1));
          final dots = ((t - 0.5) / 0.35).clamp(0.0, 1.0);
          final num5 = ((t - 0.4) / 0.3).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _LogoPainter(draw: draw, dots: dots)),
              ),
              Opacity(
                opacity: num5,
                child: Transform.scale(
                  scale: 0.3 + 0.7 * num5,
                  child: Text('٥', style: AppText.h(size * 0.38, color: AppColors.accent)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.draw, required this.dots});
  final double draw;
  final double dots;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final path = Path();
    for (var i = 0; i < SplashLogo._pts.length; i++) {
      final p = SplashLogo._pts[i] * s;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * draw),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * s
          ..strokeJoin = StrokeJoin.miter
          ..color = AppColors.accent,
      );
    }

    final d = 8 * s * dots;
    for (final p in SplashLogo._pts) {
      final c = p * s;
      canvas.drawRect(
        Rect.fromCenter(center: c, width: d, height: d),
        Paint()..color = AppColors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.draw != draw || old.dots != dots;
}
