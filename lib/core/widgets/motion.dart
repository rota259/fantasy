import 'package:flutter/material.dart';

/// حركة التطبيق: هادية وسريعة (من ١٥٠ لـ ٤٥٠ ملّي ثانية) عشان التطبيق يحسّ ناعم من غير ما يبطّأ.
abstract final class Motion {
  Motion._();

  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;

  /// الموبايل مفعّل "تقليل الحركة" (أو أجهزة ضعيفة) → الاحتفالات والحركات المتكررة بتتلغي.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// العنصر بيدخل بظهور تدريجي + طلوع خفيف. [index] بيأخّر كل عنصر شوية عن اللي قبله (قايمة متتابعة).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 14});

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.slow);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Motion.curve);

  @override
  void initState() {
    super.initState();
    // أول ١٢ عنصر بس بيتأخّروا — الباقي بيظهر مع آخرهم (القايمة الطويلة متستناش)
    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 12));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, (1 - _t.value) * widget.offset), child: child),
      ),
      child: widget.child,
    );
  }
}

/// زرار/عنصر بيتضغط: بيصغر سنة وهو متداس عليه (إحساس لمس حقيقي).
/// بديل GestureDetector لـ onTap بس.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.behavior, this.scale = 0.97});

  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior? behavior;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.fast,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}

/// رقم بيعدّ لحد قيمته (النقط مثلًا).
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutQuart,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// تبديل ناعم بين حالتين (تحميل ← محتوى، أو قيمة ← قيمة): ظهور تدريجي + طلوع خفيف.
class SoftSwitcher extends StatelessWidget {
  const SoftSwitcher({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Motion.curve,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
