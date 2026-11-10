import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

part 'formation_pitch_widgets.dart';

/// توكن موضوع على الأرض بنسبة مئوية من العرض/الطول.
class PitchToken {
  const PitchToken({required this.leftPct, required this.topPct, required this.child});
  final double leftPct;
  final double topPct;
  final Widget child;
}

/// ألوان الملعب الكلاسيك: فريم · خط أبيض · نجيلة خضرا بدرجتين · لاعيبة الجولة بالدهبي.
abstract final class PitchColors {
  static const frame = Color(0xFF0A3B2F); // زيتي غامق (ملعب تشكيلتك)
  static const forest = Color(0xFF0A3B2F); // نفس الفريم (تشكيلة الجولة)
  static const grass = Color(0xFF17805F);
  static const grassStripe = Color(0xFF1B8C68);
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
