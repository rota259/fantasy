import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// خلفية ملعب أخضر (نجيلة مخطّطة + خطوط + كورة) — للفيديوهات اللي مالهاش صورة.
class PitchBackdrop extends StatelessWidget {
  const PitchBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PitchPainter(),
      child: const Align(
        alignment: Alignment(0.35, 0.3),
        child: Text('⚽', style: TextStyle(fontSize: 30)),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // نجيلة: شرايط رأسية فاتح/غامق
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.accent600);
    final stripe = Paint()..color = AppColors.accent500;
    final band = w / 10;
    for (var x = 0.0; x < w; x += band * 2) {
      canvas.drawRect(Rect.fromLTWH(x, 0, band, h), stripe);
    }
    // الخطوط
    final line = Paint()
      ..color = AppColors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final pad = h * 0.08;
    canvas.drawRect(Rect.fromLTRB(pad, pad, w - pad, h - pad), line);
    canvas.drawLine(Offset(w / 2, pad), Offset(w / 2, h - pad), line);
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.18, line);
    canvas.drawCircle(Offset(w / 2, h / 2), 3, line..style = PaintingStyle.fill);
    line.style = PaintingStyle.stroke;
    // منطقتين الجزا
    final boxH = h * 0.5, boxW = w * 0.12;
    canvas.drawRect(Rect.fromLTWH(pad, (h - boxH) / 2, boxW, boxH), line);
    canvas.drawRect(Rect.fromLTWH(w - pad - boxW, (h - boxH) / 2, boxW, boxH), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
