import 'package:flutter/material.dart';

import '../theme/app_text.dart';

part 'story_parts_extra.dart';

/// ألوان كروت الشير (ثابتة — الكارت بيطلع صورة فمبيتغيّرش مع الوضع الداكن).
abstract final class StoryColors {
  static const forest = Color(0xFF0A3B2F);
  static const deep = Color(0xFF05241C);
  static const grass = Color(0xFF17805F);
  static const lime = Color(0xFFC8F169);
  static const ink = Color(0xFF12211C);
  static const gold = Color(0xFFF2C14E);
}

/// خلفية الكارت: تدريج + خطوط ملعب خفيفة (دايرة السنتر والمنطقتين) + وهج في الركن.
class StoryBackdrop extends StatelessWidget {
  const StoryBackdrop({
    super.key,
    required this.child,
    this.colors = const [StoryColors.forest, StoryColors.deep],
    this.line = Colors.white,
    this.glow = StoryColors.lime,
  });

  final Widget child;
  final List<Color> colors;
  final Color line, glow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
    ),
    child: CustomPaint(painter: _PitchLines(line, glow), child: child),
  );
}

class _PitchLines extends CustomPainter {
  _PitchLines(this.line, this.glow);
  final Color line, glow;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawCircle(
      Offset(w * 0.92, h * 0.04),
      w * 0.85,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: 0.22), glow.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(w * 0.92, h * 0.04), radius: w * 0.85)),
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.006
      ..color = line.withValues(alpha: 0.09);
    final m = w * 0.035;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(m, m, w - m, h - m), Radius.circular(w * 0.04)), p);
    canvas.drawLine(Offset(m, h / 2), Offset(w - m, h / 2), p);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.24, p);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.012, Paint()..color = line.withValues(alpha: 0.12));
    for (final top in [true, false]) {
      final y = top ? m : h - m;
      final d = top ? 1.0 : -1.0;
      canvas.drawRect(Rect.fromLTRB(w * 0.24, y, w * 0.76, y + d * h * 0.11), p);
      canvas.drawRect(Rect.fromLTRB(w * 0.38, y, w * 0.62, y + d * h * 0.045), p);
    }
  }

  @override
  bool shouldRepaint(covariant _PitchLines o) => o.line != line || o.glow != glow;
}

/// كبسولة صغيرة (الجولة · المنطقة · «طلعت ٣ مراكز»). [filled] = متلوّنة كلها.
class StoryPill extends StatelessWidget {
  const StoryPill(
    this.text, {
    super.key,
    this.icon,
    this.color = StoryColors.lime,
    this.onColor = StoryColors.ink,
    this.filled = false,
    this.size = 11,
  });

  final String text;
  final IconData? icon;
  final Color color, onColor;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? onColor : color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size, vertical: size * 0.45),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: size * 1.35, color: fg), SizedBox(width: size * 0.4)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h(size, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
