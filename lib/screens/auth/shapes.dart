import 'dart:math';
import 'package:fantasy_5omasi/themes/app_color.dart';
import 'package:flutter/material.dart';

class IconBackgroundPainter extends CustomPainter {
  final Random seededRandom = Random(2025); // توزيع ثابت

  final List<String> icons = [
    '⚽', // كرة قدم
    '🏆', // كأس دوري الأبطال
    '🛡️', // درع الدوري الإنجليزي
    '⭐', // نجمة
    '👕', // قميص فريق
  ];

  final List<Color> colors = [
    AppColors.primary.withOpacity(0.12),
    AppColors.backgroundSoft.withOpacity(0.12),
    AppColors.success.withOpacity(0.12),
  ];

  final double iconSize = 40;
  final double minSpacing = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final placedPositions = <Offset>[];

    int maxIcons = 50;
    int placed = 0;
    int attempts = 0;

    while (placed < maxIcons && attempts < maxIcons * 50) {
      final icon = icons[seededRandom.nextInt(icons.length)];
      final color = colors[seededRandom.nextInt(colors.length)];

      final x = seededRandom.nextDouble() * (size.width - iconSize);
      final y = seededRandom.nextDouble() * (size.height - iconSize);
      final position = Offset(x, y);

      final isFarEnough = placedPositions.every(
        (p) => (p - position).distance >= minSpacing,
      );

      if (isFarEnough) {
        placedPositions.add(position);
        placed++;

        final painter = TextPainter(
          text: TextSpan(
            text: icon,
            style: TextStyle(
              fontSize: iconSize,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        painter.paint(canvas, position);
      }

      attempts++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
