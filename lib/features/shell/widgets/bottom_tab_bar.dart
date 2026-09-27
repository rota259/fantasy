import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../cubit/app_nav_cubit.dart';
import '../../../core/widgets/motion.dart';

/// شريط التابات السفلي: 5 تابات، النشط بأخضر مع مؤشّر فوقه.
class BottomTabBar extends StatelessWidget {
  const BottomTabBar({super.key, required this.current, required this.onTap});

  final AppTab current;
  final ValueChanged<AppTab> onTap;

  static const _items = [
    (AppTab.home, Icons.home_outlined, 'الرئيسية'),
    (AppTab.team, Icons.grid_view_outlined, 'فريقي'),
    (AppTab.market, Icons.people_outline, 'اللاعيبة'),
    (AppTab.leagues, Icons.bar_chart, 'الدوريات'),
    (AppTab.account, Icons.person_outline, 'حسابي'),
  ];

  @override
  Widget build(BuildContext context) {
    // شريط عايم ناعم: كارت بزوايا مدوّرة وظل، والتاب النشط عليه كبسولة خضرا بتتحرك
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (final it in _items)
                Expanded(
                  child: Pressable(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(it.$1),
                    child: _TabItem(icon: it.$2, label: it.$3, active: it.$1 == current),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.active});

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.neutral600;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.curve,
          padding: EdgeInsets.symmetric(horizontal: active ? 18 : 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.accent100 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedScale(
            scale: active ? 1.12 : 1,
            duration: Motion.medium,
            curve: Motion.curve,
            child: Icon(icon, size: 21, color: color),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: Motion.medium,
          style: AppText.body(9, color: color, weight: active ? FontWeight.w800 : FontWeight.w600),
          child: Text(label),
        ),
      ],
    );
  }
}
