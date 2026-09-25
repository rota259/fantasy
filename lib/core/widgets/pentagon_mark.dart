import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// علامة "الخماسي": مضلّع أخضر ثابت مع رقم 5 في النص.
class PentagonMark extends StatelessWidget {
  const PentagonMark({super.key, this.size = 56, this.stroke = 5});

  final double size;
  final double stroke;

  static const List<Offset> _pts = [
    Offset(50, 16),
    Offset(82.3, 39.5),
    Offset(70, 77.5),
    Offset(30, 77.5),
    Offset(17.7, 39.5),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _MarkPainter(stroke))),
          Text('5', style: AppText.h(size * 0.42, color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.stroke);
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final path = Path();
    for (var i = 0; i < PentagonMark._pts.length; i++) {
      final p = PentagonMark._pts[i] * s;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * s
        ..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
