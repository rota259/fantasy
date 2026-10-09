import 'package:flutter/material.dart';

import '../motion.dart';

/// دهبي معدني حقيقي (مش أصفر): تدرّج غامق ← فاتح ← غامق زي المعدن، ولمعة بيضا بتعدّي عليه كل شوية.
/// [shape] شكل السطح (مستطيل مدوّر · خماسي · دايرة) — اللمعة بتتقص عليه.
class GoldShine extends StatefulWidget {
  const GoldShine({super.key, this.child, this.shape, this.padding, this.width, this.height, this.delay = 0});

  final Widget? child;
  final ShapeBorder? shape; // الافتراضي مستطيل حوافه ١٠
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double delay; // 0..1 — إزاحة اللمعة عشان مايلمعوش كلهم سوا

  /// ألوان المعدن.
  static const metal = [Color(0xFF7A5410), Color(0xFFC9971C), Color(0xFFFFE7A0), Color(0xFFD9A92B), Color(0xFF8C6212)];
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: metal,
    stops: [0, 0.3, 0.5, 0.7, 1],
  );

  @override
  State<GoldShine> createState() => _GoldShineState();
}

class _GoldShineState extends State<GoldShine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));

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
    final shape = widget.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape, textDirection: Directionality.of(context)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: const BoxDecoration(gradient: GoldShine.gradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // اللمعة: شريط أبيض مايل بيعدّي في أول ٤٠٪ من الدورة وبعدين يرتاح
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) {
                    final t = ((_c.value + widget.delay) % 1) / 0.4;
                    final x = -1.5 + 3 * t.clamp(0.0, 1.0);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(x - 0.6, -1),
                          end: Alignment(x + 0.6, 1),
                          colors: const [Color(0x00FFFFFF), Color(0xB3FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (widget.child != null) Padding(padding: widget.padding ?? EdgeInsets.zero, child: widget.child),
          ],
        ),
      ),
    );
  }
}
