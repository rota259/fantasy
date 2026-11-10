import 'dart:math';

import 'package:flutter/material.dart';

import '../motion.dart';

part 'effects_extra.dart';

/// هزة خفيفة مرة واحدة أول ما يظهر (لحظة الجول).
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child, this.strength = 10});
  final Widget child;
  final double strength;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(sin(_c.value * pi * 8) * widget.strength * (1 - _c.value), 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// نبض متكرر: هالة بلون [color] بتكبر وتصغر حوالين العنصر (اللاعب اللي بيلعب دلوقتي).
class PulseGlow extends StatefulWidget {
  const PulseGlow({super.key, required this.child, required this.color, this.enabled = true});
  final Widget child;
  final Color color;
  final bool enabled;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PulseGlow old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final on = widget.enabled && !Motion.reduced(context);
    if (on && !_c.isAnimating) _c.repeat(reverse: true);
    if (!on && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.35 + 0.5 * _c.value),
              blurRadius: 8 + 14 * _c.value,
              spreadRadius: 1 + 3 * _c.value,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// حلقة دهبي بتلف حوالين العنصر (الكابتن).
class SpinRing extends StatefulWidget {
  const SpinRing({super.key, required this.child, required this.size, this.color = const Color(0xFFF2C14E)});
  final Widget child;
  final double size;
  final Color color;

  @override
  State<SpinRing> createState() => _SpinRingState();
}

/// كلام بيطلع لفوق ويختفي (+٥ فوق اللاعب).
class FloatUp extends StatefulWidget {
  const FloatUp({super.key, required this.child, this.distance = 36});
  final Widget child;
  final double distance;

  @override
  State<FloatUp> createState() => _FloatUpState();
}
