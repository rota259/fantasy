import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// توكن موضوع على الأرض بنسبة مئوية من العرض/الطول.
class PitchToken {
  const PitchToken({required this.leftPct, required this.topPct, required this.child});
  final double leftPct;
  final double topPct;
  final Widget child;
}

/// ألوان الملعب الكلاسيك: فريم نبيتي · خط أبيض · نجيلة خضرا بدرجتين · لاعيبة الجولة بالدهبي.
abstract final class PitchColors {
  static const frame = Color(0xFF5E1520); // نبيتي غامق (ملعب تشكيلتك)
  static const forest = Color(0xFF173F1B); // أخضر غابة غامق (تشكيلة الجولة — من غير نبيتي)
  static const grass = Color(0xFF2E7D32);
  static const grassStripe = Color(0xFF388E3C);
  static const line = Color(0xE6FFFFFF);
  static const gold = Color(0xFFE8B931);
  static const goldDeep = Color(0xFF8A6410);
}

/// أرض ملعب خماسية: خطوط نجيلة + مضلّع + توكنات اللاعيبة.
/// [framed]: الستايل الكلاسيك — مستطيل بفريم ([frameColor] — نبيتي افتراضيًا)، جواه خط أبيض محدّد الملعب، والأرض خضرا.
class PentagonPitch extends StatelessWidget {
  const PentagonPitch({
    super.key,
    required this.height,
    required this.tokens,
    this.border,
    this.background,
    this.stripe,
    this.line = const Color(0x8C4FCA85), // rgba(79,202,133,.55)
    this.shape = pentagon,
    this.framed = false,
    this.frameColor = PitchColors.frame,
  });

  final double height;
  final List<PitchToken> tokens;
  final Border? border;

  /// ألوان الأرضية (لو مش framed).
  final Color? background; // الافتراضي night
  final Color? stripe; // الافتراضي nightStripe
  final Color line;

  /// رؤوس المضلّع المرسوم (نِسَب 0..1): خماسي (الافتراضي) أو سداسي.
  final List<Offset> shape;
  final bool framed;
  final Color frameColor; // لون الفريم

  /// رؤوس المضلّع (نِسَب 0..1) — مطابقة للـ handoff.
  static const List<Offset> pentagon = [
    Offset(0.50, 0.86),
    Offset(0.84, 0.60),
    Offset(0.71, 0.20),
    Offset(0.29, 0.20),
    Offset(0.16, 0.60),
  ];

  /// ملعب سداسي: الحارس تحت + ٥.
  static const List<Offset> hexagon = [
    Offset(0.50, 0.88),
    Offset(0.85, 0.68),
    Offset(0.85, 0.30),
    Offset(0.50, 0.12),
    Offset(0.15, 0.30),
    Offset(0.15, 0.68),
  ];

  @override
  Widget build(BuildContext context) {
    final ground = Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: framed
                ? _PitchPainter(PitchColors.grassStripe, PitchColors.line, shape, boundary: true)
                : _PitchPainter(stripe ?? AppColors.nightStripe, line, shape),
          ),
        ),
        for (final t in tokens) Align(alignment: Alignment(t.leftPct / 50 - 1, t.topPct / 50 - 1), child: t.child),
      ],
    );
    if (!framed) {
      return Container(
        height: height,
        decoration: BoxDecoration(color: background ?? AppColors.night, border: border),
        clipBehavior: Clip.hardEdge,
        child: ground,
      );
    }
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ClipRect(
        child: ColoredBox(color: PitchColors.grass, child: ground),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  _PitchPainter(this.stripeColor, this.lineColor, this.shape, {this.boundary = false});
  final Color stripeColor;
  final Color lineColor;
  final List<Offset> shape;
  final bool boundary; // خط أبيض محدّد الملعب جوه الفريم

  @override
  void paint(Canvas canvas, Size size) {
    // خطوط النجيلة الأفقية
    final stripe = Paint()..color = stripeColor;
    const band = 26.0;
    for (double y = band; y < size.height; y += band * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, band), stripe);
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = lineColor;
    if (boundary) {
      canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), stroke..strokeWidth = 2.5);
    }
    // مضلّع الأرض
    final path = Path();
    for (var i = 0; i < shape.length; i++) {
      final p = shape[i];
      final o = Offset(p.dx * size.width, p.dy * size.height);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    path.close();
    canvas.drawPath(path, stroke..strokeWidth = boundary ? 2 : 1);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter old) =>
      old.stripeColor != stripeColor || old.lineColor != lineColor || old.shape != shape || old.boundary != boundary;
}
