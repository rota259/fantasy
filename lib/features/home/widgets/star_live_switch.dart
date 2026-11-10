part of 'star_of_week_card.dart';

/// سويتش صغير فوق كارت النجم: «اللي خلصت» (نهائي) ↔ «لحد دلوقتي» (لايف، بنقطة حمرا بتنبض).
class _LiveSwitch extends StatelessWidget {
  const _LiveSwitch({required this.live, required this.onChanged});
  final bool live;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(99)),
    child: Row(
      children: [
        _seg('الجولة اللي خلصت', !live, () => onChanged(false)),
        _seg('الحالية لحد دلوقتي', live, () => onChanged(true), dot: true),
      ],
    ),
  );

  Widget _seg(String text, bool on, VoidCallback onTap, {bool dot = false}) => Expanded(
    child: Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppColors.accent400 : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (dot) ...[PulseDot(color: on ? AppColors.black : AppColors.danger), const SizedBox(width: 5)],
            Text(text, style: AppText.h(11, color: on ? AppColors.black : AppColors.white)),
          ],
        ),
      ),
    ),
  );
}

/// نقطة «لايف» بتنبض.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color});
  final Color color;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
    child: Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}
