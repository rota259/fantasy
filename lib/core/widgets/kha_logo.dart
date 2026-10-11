import 'dart:math' as math;

import 'package:flutter/material.dart';

/// لوجو الخماسي: حرف «خ» كوفي هندسي ونقطته كورة ("ح + كورة = خ").
/// مرسوم بالكود (viewBox 100×100) بنفس هندسة ملف التصميم — فبيتلوّن ويتحرّك زي ما نحب.
///   الحرف:  M24 44 H72 L32 66 Q20 73 25 83 Q30 91 48 91 H80  (أطراف مربعة)
///   الكورة: دايرة (48,22) نصف قطرها 11، وجواها رقعة خماسية.
class KhaLogo extends StatelessWidget {
  const KhaLogo({
    super.key,
    this.size = 48,
    this.letter = Colors.white,
    this.ball = brightGreen,
    this.patch = Colors.black,
    this.ballDy = 0,
    this.ballTurns = 0,
    this.ballOpacity = 1,
  });

  /// أخضر النجيلة (الأيقونة) · الأخضر الفاتح (على الأسود) · الحبر.
  static const turf = Color(0xFF12A150);
  static const brightGreen = Color(0xFF46C67C);
  static const ink = Color(0xFF201E1D);

  final double size;
  final Color letter, ball, patch;

  /// للحركة: إزاحة الكورة لفوق/تحت (بوحدات اللوجو ١٠٠) · لفّتها (١ = لفة كاملة) · شفافيتها.
  final double ballDy, ballTurns, ballOpacity;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _KhaPainter(letter, ball, patch, ballDy, ballTurns, ballOpacity));
}

class _KhaPainter extends CustomPainter {
  _KhaPainter(this.letter, this.ball, this.patch, this.ballDy, this.ballTurns, this.ballOpacity);
  final Color letter, ball, patch;
  final double ballDy, ballTurns, ballOpacity;

  static const _patch = [Offset(48, 17), Offset(52.8, 20.5), Offset(51, 26), Offset(45, 26), Offset(43.2, 20.5)];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);
    // تحت ٢٨ بكسل: سُمك أتخن وكورة سادة (من غير الرقعة) عشان يفضل واضح
    final small = size.width < 28;
    final path = Path()
      ..moveTo(24, 44)
      ..lineTo(72, 44)
      ..lineTo(32, 66)
      ..quadraticBezierTo(20, 73, 25, 83)
      ..quadraticBezierTo(30, 91, 48, 91)
      ..lineTo(80, 91);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = small ? 13 : 11
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter
        ..color = letter,
    );
    if (ballOpacity <= 0) return;
    canvas.save();
    canvas.translate(48, 22 + ballDy);
    canvas.rotate(ballTurns * 2 * math.pi);
    canvas.translate(-48, -22);
    canvas.drawCircle(const Offset(48, 22), small ? 12 : 11, Paint()..color = ball.withValues(alpha: ballOpacity));
    if (!small) {
      canvas.drawPath(Path()..addPolygon(_patch, true), Paint()..color = patch.withValues(alpha: ballOpacity));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KhaPainter o) =>
      o.letter != letter ||
      o.ball != ball ||
      o.patch != patch ||
      o.ballDy != ballDy ||
      o.ballTurns != ballTurns ||
      o.ballOpacity != ballOpacity;
}
