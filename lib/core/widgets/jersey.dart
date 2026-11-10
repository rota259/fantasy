import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import 'motion.dart';

part 'jersey_widgets.dart';

/// ألوان التيشيرت: القماش (فاتح ← غامق للتظليل) + الياقة والأكمام + لون الكلام.
class JerseyStyle {
  const JerseyStyle({required this.body, required this.trim, required this.ink, this.shine = 0x55});
  final List<Color> body; // من النص للأطراف
  final Color trim;
  final Color ink;
  final int shine; // شفافية اللمعة (0 = من غير)

  /// تشكيلتك: أبيض والكلام أسود.
  static const white = JerseyStyle(
    body: [Color(0xFFFFFFFF), Color(0xFFE4E4E0)],
    trim: Color(0xFF1C1C1C),
    ink: Color(0xFF1C1C1C),
  );

  /// الحارس: رمادي فحمي والكلام أبيض.
  static const keeper = JerseyStyle(
    body: [Color(0xFF4A4A4A), Color(0xFF1F1F1F)],
    trim: Color(0xFFE8E8E8),
    ink: Colors.white,
  );

  /// الكابتن وتشكيلة الجولة: دهب معدني بيلمع.
  static const gold = JerseyStyle(
    body: [Color(0xFFFFE7A0), Color(0xFFD9A92B), Color(0xFF8C6212)],
    trim: Color(0xFF5A3D05),
    ink: Color(0xFF3A2600),
    shine: 0xB3,
  );
}

/// تيشيرت لاعب زي FPL — مرسوم (مش صورة): تظليل قماش + ياقة وأكمام + الحروف على الصدر.
/// الحركة: بيتمايل بهدوء زي ما يكون متعلّق، ولمعة بتعدّي عليه كل شوية (كل تيشيرت بتوقيت مختلف).
class Jersey extends StatefulWidget {
  const Jersey({super.key, required this.label, this.style = JerseyStyle.white, this.size = 50, this.phase = 0});

  final String label; // الحروف أو الرقم على الصدر
  final JerseyStyle style;
  final double size; // العرض
  final double phase; // 0..1

  @override
  State<Jersey> createState() => _JerseyState();
}

class _JerseyState extends State<Jersey> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size;
    final h = w * 0.96;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final v = (_c.value + widget.phase) % 1;
        return Transform.rotate(
          angle: 0.035 * math.sin(v * 2 * math.pi), // تمايل خفيف
          alignment: Alignment.topCenter,
          child: CustomPaint(
            size: Size(w, h),
            painter: _JerseyPainter(widget.style, (v / 0.35).clamp(0.0, 1.0)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: w,
        height: h,
        child: Padding(
          padding: EdgeInsets.only(top: h * 0.3, left: w * 0.22, right: w * 0.22),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.label, style: AppText.h(w * 0.26, color: widget.style.ink)),
          ),
        ),
      ),
    );
  }
}
