part of 'leagues_widgets.dart';

/// سهم طلع/نزل كام مركز — بيتنطّط مرة لما يظهر.
class _Moved extends StatelessWidget {
  const _Moved(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    final up = n > 0;
    final color = up ? AppColors.accent : AppColors.danger;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (_, t, c) => Transform.translate(offset: Offset(0, (1 - t) * (up ? 10 : -10)), child: c),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Text('${up ? '▲' : '▼'}${n.abs()}', style: AppText.h(11, color: color)),
      ),
    );
  }
}
