import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../cubit/app_nav_cubit.dart';

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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: _items.map((it) {
              final active = it.$1 == current;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(it.$1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 3, width: 24, color: active ? AppColors.accent : Colors.transparent),
                      const SizedBox(height: 9),
                      Icon(it.$2, size: 21, color: active ? AppColors.accent : AppColors.neutral600),
                      const SizedBox(height: 3),
                      Text(
                        it.$3,
                        style: AppText.body(
                          8.5,
                          color: active ? AppColors.accent : AppColors.neutral600,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
