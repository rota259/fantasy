import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان الهوية (ثابتة — مش بتتغيّر مع الوضع الداكن).
abstract final class Brand {
  static const turf = Color(0xFF12A150); // أخضر النجيلة
  static const brightGreen = Color(0xFF46C67C); // على الأسود
  static const ink = Color(0xFF201E1D);
  static const paper = Color(0xFFF3F2F2); // خلفية اللوجو الفاتحة
}

/// لوجو الخماسي: صديري التمرين وعليه رقم 5 مرسوم زي خطوط الملعب (بطن الـ5 = دايرة السنتر وجواها نقطة السنتر).
/// مرسوم بالكود (viewBox 100×100) بنفس هندسة ملف التصميم:
///   الصديري: M33 9 H43 C45 21 55 21 57 9 H67 C67 22 73 28 81 30 V91 H19 V30 C27 28 33 22 33 9 Z
///   الـ5 (جوه translate(17 26.8) scale(.66)): M72 14 H30 V50.7 A24 24 0 1 1 33 81 · نقطة السنتر (50,64)
class BibLogo extends StatelessWidget {
  const BibLogo({
    super.key,
    this.size = 48,
    this.bib = Brand.turf,
    this.five = Colors.white,
    this.spot = Brand.ink,
    this.draw = 1,
    this.spotScale = 1,
    this.angle = 0,
  });

  /// على الأسطح الغامقة: صديري أخضر فاتح و5 سودا ونقطة بيضا.
  const BibLogo.onDark({super.key, this.size = 48, this.draw = 1, this.spotScale = 1, this.angle = 0})
    : bib = Brand.brightGreen,
      five = Colors.black,
      spot = Colors.white;

  final double size;
  final Color bib, five, spot;

  /// للحركة: نسبة رسم الـ5 (0..1) · حجم نقطة السنتر · زاوية تمايل الصديري من رقبته (راديان).
  final double draw, spotScale, angle;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _BibPainter(bib, five, spot, draw, spotScale, angle));
}

class _BibPainter extends CustomPainter {
  _BibPainter(this.bib, this.five, this.spot, this.draw, this.spotScale, this.angle);
  final Color bib, five, spot;
  final double draw, spotScale, angle;

  static final Path _bib = Path()
    ..moveTo(33, 9)
    ..lineTo(43, 9)
    ..cubicTo(45, 21, 55, 21, 57, 9)
    ..lineTo(67, 9)
    ..cubicTo(67, 22, 73, 28, 81, 30)
    ..lineTo(81, 91)
    ..lineTo(19, 91)
    ..lineTo(19, 30)
    ..cubicTo(27, 28, 33, 22, 33, 9)
    ..close();

  static final Path _five = Path()
    ..moveTo(72, 14)
    ..lineTo(30, 14)
    ..lineTo(30, 50.7)
    ..arcToPoint(const Offset(33, 81), radius: const Radius.circular(24), largeArc: true);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final small = size.width < 28;
    // التمايل من الرقبة (زي ما يكون متعلّق على مسمار)
    if (angle != 0) {
      canvas.translate(50, 8);
      canvas.rotate(angle);
      canvas.translate(-50, -8);
    }
    canvas.drawPath(_bib, Paint()..color = bib);
    canvas.save();
    canvas.translate(17, 26.8);
    canvas.scale(0.66);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..color = five;
    if (draw >= 1) {
      canvas.drawPath(_five, stroke);
    } else if (draw > 0) {
      for (final m in _five.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * draw), stroke);
      }
    }
    // نقطة السنتر (بتتشال في المقاسات الصغيرة)
    if (!small && spotScale > 0) {
      canvas.drawCircle(const Offset(50, 64), 7 * math.max(0, spotScale), Paint()..color = spot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BibPainter o) =>
      o.bib != bib ||
      o.five != five ||
      o.spot != spot ||
      o.draw != draw ||
      o.spotScale != spotScale ||
      o.angle != angle;
}

/// اسم «الخماسي» بخط الهوية (ثقيل بزخرفة عربي) — لشاشة البداية والدخول والعناوين الكبيرة.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 34, this.color = Brand.ink});
  final double size;
  final Color color;

  static TextStyle style(double size, Color color) => GoogleFonts.rakkas(fontSize: size, color: color, height: 1.1);

  @override
  Widget build(BuildContext context) => Text('الخماسي', style: style(size, color));
}

/// اللوجو والاسم جنب بعض (اللوجو على اليمين والاسم على شماله) — نفس شكل الهوية.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.height = 56, this.onDark = false});
  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    textDirection: TextDirection.rtl,
    children: [
      onDark ? BibLogo.onDark(size: height) : BibLogo(size: height),
      SizedBox(width: height * 0.22),
      BrandWordmark(size: height * 0.78, color: onDark ? Colors.white : Brand.ink),
    ],
  );
}
