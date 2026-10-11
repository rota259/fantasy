import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// توكن موضوع على الأرض بنسبة مئوية من العرض/الطول.
class PitchToken {
  const PitchToken({required this.leftPct, required this.topPct, required this.child});
  final double leftPct;
  final double topPct;
  final Widget child;
}

/// ألوان الملعب الكلاسيك: فريم · خط أبيض · نجيلة خضرا بدرجتين · لاعيبة الجولة بالدهبي.
abstract final class PitchColors {
  static const frame = Color(0xFF5E1520); // نبيتي غامق (ملعب تشكيلتك)
  static const forest = Color(0xFF173F1B); // أخضر غابة غامق (تشكيلة الجولة)
  static const grass = Color(0xFF2E7D32);
  static const grassStripe = Color(0xFF388E3C);
  static const line = Color(0xE6FFFFFF);
  static const gold = Color(0xFFE8B931);
  static const goldDeep = Color(0xFF8A6410);
}

/// أرض ملعب بخطوطه الحقيقية (نص الملعب · دايرة السنتر · منطقة المرمى) + توكنات اللاعيبة في أماكنهم.
/// [framed]: الستايل الكلاسيك — مستطيل بفريم ([frameColor])، جواه خط أبيض محدّد الملعب، والأرض خضرا.
class FormationPitch extends StatelessWidget {
  const FormationPitch({
    super.key,
    required this.height,
    required this.tokens,
    this.border,
    this.background,
    this.stripe,
    this.line = const Color(0x8C4FCA85), // rgba(79,202,133,.55)
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
  final bool framed;
  final Color frameColor; // لون الفريم

  /// أماكن الخماسي (نِسَب 0..1): الحارس تحت + ٤.
  static const List<Offset> five = [
    Offset(0.50, 0.86),
    Offset(0.84, 0.60),
    Offset(0.71, 0.20),
    Offset(0.29, 0.20),
    Offset(0.16, 0.60),
  ];

  /// أماكن السداسي: الحارس تحت + ٥.
  static const List<Offset> six = [
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
                ? _PitchPainter(PitchColors.grassStripe, PitchColors.line, boundary: true)
                : _PitchPainter(stripe ?? AppColors.nightStripe, line),
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
  _PitchPainter(this.stripeColor, this.lineColor, {this.boundary = false});
  final Color stripeColor;
  final Color lineColor;
  final bool boundary; // خط أبيض محدّد الملعب جوه الفريم

  @override
  void paint(Canvas canvas, Size size) {
    // خطوط النجيلة الأفقية
    final stripe = Paint()..color = stripeColor;
    const band = 26.0;
    for (double y = band; y < size.height; y += band * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, band), stripe);
    }
    final w = size.width, h = size.height;
    final inset = boundary ? 8.0 : 0.0;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = boundary ? 2 : 1
      ..color = lineColor;
    if (boundary) {
      canvas.drawRect(Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2), stroke..strokeWidth = 2.5);
      stroke.strokeWidth = 2;
    }
    // خط النص ودايرة السنتر
    final mid = h * 0.42;
    canvas.drawLine(Offset(inset, mid), Offset(w - inset, mid), stroke);
    canvas.drawCircle(Offset(w / 2, mid), w * 0.13, stroke);
    canvas.drawCircle(Offset(w / 2, mid), 2.5, Paint()..color = lineColor);
    // منطقة المرمى تحت (عند الحارس) + قوسها
    final boxW = w * 0.46, boxH = h * 0.2;
    final box = Rect.fromLTWH((w - boxW) / 2, h - inset - boxH, boxW, boxH);
    canvas.drawRect(box, stroke);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, box.top), width: w * 0.2, height: w * 0.12),
      3.14159,
      3.14159,
      false,
      stroke,
    );
    // المرمى نفسه
    final goalW = w * 0.2;
    canvas.drawRect(Rect.fromLTWH((w - goalW) / 2, h - inset - 5, goalW, 5), Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter old) =>
      old.stripeColor != stripeColor || old.lineColor != lineColor || old.boundary != boundary;
}
