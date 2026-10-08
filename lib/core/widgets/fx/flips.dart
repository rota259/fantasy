import 'dart:math';

import 'package:flutter/material.dart';

/// قلب 3D بين حالتين لما [child] يتغيّر (الكارت بيتقلب ويبان عليه C).
class FlipSwitcher extends StatelessWidget {
  const FlipSwitcher({super.key, required this.child, this.vertical = false});
  final Widget child;
  final bool vertical; // true = لوحة المطار (قلب لفوق)

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, a) => AnimatedBuilder(
        animation: a,
        builder: (_, c) {
          final angle = (1 - a.value) * pi / 2;
          final m = Matrix4.identity()..setEntry(3, 2, 0.002);
          vertical ? m.rotateX(angle) : m.rotateY(angle);
          return Transform(alignment: Alignment.center, transform: m, child: c);
        },
        child: child,
      ),
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [?current]),
      child: child,
    );
  }
}

/// رقم بيتقلب زي لوحة المطار — كل خانة لوحدها (النتيجة).
class FlipNumber extends StatelessWidget {
  const FlipNumber({super.key, required this.value, required this.style});
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final digits = '$value'.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        for (final (i, d) in digits.indexed)
          FlipSwitcher(
            vertical: true,
            child: Text(d, key: ValueKey('${digits.length}-$i-$d'), style: style),
          ),
      ],
    );
  }
}
