part of 'effects.dart';

class _SpinRingState extends State<SpinRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size + 10;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _c,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [widget.color, widget.color.withValues(alpha: 0), widget.color.withValues(alpha: 0.9)],
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _FloatUpState extends State<FloatUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeOutCubic.transform(_c.value);
          return Opacity(
            opacity: (1 - _c.value * _c.value).clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, -widget.distance * t),
              child: Transform.scale(
                scale: 0.7 + 0.5 * Curves.elasticOut.transform(min(1, _c.value * 2)),
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// عملة بتلف 3D لفتين وتقف (شارة جديدة).
class CoinSpin extends StatelessWidget {
  const CoinSpin({super.key, required this.child, this.turns = 2});
  final Widget child;
  final int turns;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(t * turns * 2 * pi),
        child: c,
      ),
      child: child,
    );
  }
}
