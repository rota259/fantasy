import 'dart:math';

import 'package:flutter/material.dart';

import '../motion.dart';

/// انفجار confetti (من غير مكتبات): ورق ملوّن بيطلع من النص ويقع بالجاذبية ويختفي.
/// بيشتغل مرة واحدة أول ما يظهر — ومع "تقليل الحركة" مبيظهرش.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.count = 70, this.colors, this.duration = const Duration(milliseconds: 2600)});

  final int count;
  final List<Color>? colors;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Piece {
  _Piece(Random r, List<Color> colors)
    : angle = -pi / 2 + (r.nextDouble() - 0.5) * pi * 1.1,
      speed = 0.55 + r.nextDouble() * 0.75,
      spin = (r.nextDouble() - 0.5) * 14,
      size = 5 + r.nextDouble() * 6,
      color = colors[r.nextInt(colors.length)],
      round = r.nextBool();

  final double angle, speed, spin, size;
  final Color color;
  final bool round;
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final r = Random();
    final colors =
        widget.colors ??
        const [Color(0xFF22A45C), Color(0xFFF2C14E), Color(0xFFFFFFFF), Color(0xFFE85D4A), Color(0xFF52C487)];
    _pieces = List.generate(widget.count, (_) => _Piece(r, colors));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _c.value), size: Size.infinite),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.42);
    final reach = size.shortestSide * 0.9;
    final paint = Paint();
    for (final p in pieces) {
      // طيران بالسرعة + جاذبية بتسحب لتحت
      final d = p.speed * reach * t;
      final x = origin.dx + cos(p.angle) * d;
      final y = origin.dy + sin(p.angle) * d + 0.9 * reach * t * t;
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2.4, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
