part of 'formation_pitch.dart';

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
