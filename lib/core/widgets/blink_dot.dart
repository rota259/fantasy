import 'package:flutter/material.dart';

/// نقطة صغيرة بتومض (LIVE). مربّعة زي الديزاين.
class BlinkDot extends StatefulWidget {
  const BlinkDot({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  State<BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<BlinkDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: _c.value < 0.5 ? 1 : 0.2,
        child: Container(width: widget.size, height: widget.size, color: widget.color),
      ),
    );
  }
}
