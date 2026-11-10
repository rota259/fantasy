part of 'jersey.dart';

class _JerseyPainter extends CustomPainter {
  _JerseyPainter(this.style, this.sweep);
  final JerseyStyle style;
  final double sweep; // 0..1 مكان اللمعة

  static Path shape(Size s) {
    Offset p(double x, double y) => Offset(x * s.width, y * s.height);
    return Path()
      ..moveTo(p(.36, .04).dx, p(.36, .04).dy)
      ..lineTo(p(.13, .11).dx, p(.13, .11).dy)
      ..lineTo(p(0, .34).dx, p(0, .34).dy)
      ..lineTo(p(.15, .44).dx, p(.15, .44).dy)
      ..lineTo(p(.21, .37).dx, p(.21, .37).dy)
      ..lineTo(p(.21, .97).dx, p(.21, .97).dy)
      ..quadraticBezierTo(p(.5, 1).dx, p(.5, 1).dy, p(.79, .97).dx, p(.79, .97).dy)
      ..lineTo(p(.79, .37).dx, p(.79, .37).dy)
      ..lineTo(p(.85, .44).dx, p(.85, .44).dy)
      ..lineTo(p(1, .34).dx, p(1, .34).dy)
      ..lineTo(p(.87, .11).dx, p(.87, .11).dy)
      ..lineTo(p(.64, .04).dx, p(.64, .04).dy)
      ..quadraticBezierTo(p(.5, .2).dx, p(.5, .2).dy, p(.36, .04).dx, p(.36, .04).dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape(size);
    final rect = Offset.zero & size;
    // ظل تحت التيشيرت على النجيلة
    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // القماش: فاتح في النص وبيغمق ناحية الأطراف (إحساس 3D)
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(center: const Alignment(0, -0.3), radius: 0.9, colors: style.body).createShader(rect),
    );
    canvas.save();
    canvas.clipPath(path);
    // الأكمام
    final trim = Paint()..color = style.trim;
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, .34 * h)
        ..lineTo(.15 * w, .44 * h)
        ..lineTo(.17 * w, .40 * h)
        ..lineTo(.02 * w, .30 * h)
        ..close(),
      trim,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, .34 * h)
        ..lineTo(.85 * w, .44 * h)
        ..lineTo(.83 * w, .40 * h)
        ..lineTo(.98 * w, .30 * h)
        ..close(),
      trim,
    );
    // اللمعة
    if (style.shine > 0 && sweep < 1) {
      final x = -0.5 + 2 * sweep;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(x * 2 - 1.6, -1),
            end: Alignment(x * 2 - 0.4, 1),
            colors: [const Color(0x00FFFFFF), Color.fromARGB(style.shine, 255, 255, 255), const Color(0x00FFFFFF)],
          ).createShader(rect),
      );
    }
    canvas.restore();
    // الياقة
    canvas.drawPath(
      Path()
        ..moveTo(.36 * w, .04 * h)
        ..quadraticBezierTo(.5 * w, .2 * h, .64 * w, .04 * h),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..color = style.trim,
    );
    // حدود خفيفة
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x33000000),
    );
  }

  @override
  bool shouldRepaint(covariant _JerseyPainter old) => old.sweep != sweep || old.style != style;
}
