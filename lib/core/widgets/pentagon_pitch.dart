import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// توكن موضوع على الأرض بنسبة مئوية من العرض/الطول.
class PitchToken {
  const PitchToken({required this.leftPct, required this.topPct, required this.child});
  final double leftPct;
  final double topPct;
  final Widget child;
}

/// أرض ملعب خماسية غامقة: خطوط نجيلة + مضلّع أخضر + توكنات اللاعيبة.
class PentagonPitch extends StatelessWidget {
  const PentagonPitch({
    super.key,
    required this.height,
    required this.tokens,
    this.border,
  });

  final double height;
  final List<PitchToken> tokens;
  final Border? border;

  /// رؤوس المضلّع (نِسَب 0..1) — مطابقة للـ handoff.
  static const List<Offset> _pentagon = [
    Offset(0.50, 0.86),
    Offset(0.84, 0.60),
    Offset(0.71, 0.20),
    Offset(0.29, 0.20),
    Offset(0.16, 0.60),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.night, border: border),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
          for (final t in tokens)
            Align(
              alignment: Alignment(t.leftPct / 50 - 1, t.topPct / 50 - 1),
              child: t.child,
            ),
        ],
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // خطوط النجيلة الأفقية
    final stripe = Paint()..color = AppColors.nightStripe;
    const band = 26.0;
    for (double y = band; y < size.height; y += band * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, band), stripe);
    }
    // مضلّع الأرض
    final path = Path();
    for (var i = 0; i < PentagonPitch._pentagon.length; i++) {
      final p = PentagonPitch._pentagon[i];
      final o = Offset(p.dx * size.width, p.dy * size.height);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x8C4FCA85), // rgba(79,202,133,.55)
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
