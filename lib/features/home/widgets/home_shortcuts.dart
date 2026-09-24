import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../shell/cubit/app_nav_cubit.dart';

/// شبكة المختصرات 3×2 — كل واحدة بتفتح overlay.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key, required this.onOpen});

  final ValueChanged<AppOverlayView> onOpen;

  static const _items = [
    (AppOverlayView.star, Icons.star_outline, 'نجم الجولة'),
    (AppOverlayView.challenge, Icons.emoji_events_outlined, 'تحدّي الجولة'),
    (AppOverlayView.fixtures, Icons.calendar_today_outlined, 'الماتشات'),
    (AppOverlayView.pitch, Icons.location_on_outlined, 'احجز ملعب'),
    (AppOverlayView.coach, Icons.auto_awesome, 'مدرّب الذكاء'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مختصرات · SHORTCUTS', style: AppText.kicker()),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.55,
            children: _items.map((it) {
              return GestureDetector(
                onTap: () => onOpen(it.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(it.$2, size: 20, color: AppColors.ink),
                      Text(it.$3, style: AppText.h(11)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
