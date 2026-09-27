import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../../core/widgets/motion.dart';

/// مختصر في الهوم: أيقونة + اسم + اللي بيحصل لما يتداس.
typedef HomeShortcut = ({IconData icon, String label, VoidCallback onTap});

/// شبكة المختصرات 3×2 — كل واحد جوه خماسي.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key, required this.items});

  final List<HomeShortcut> items;

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
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              for (final it in items)
                Pressable(
                  behavior: HitTestBehavior.opaque,
                  onTap: it.onTap,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PentagonIcon(size: 62, child: Icon(it.icon, size: 22, color: AppColors.accent)),
                      const SizedBox(height: 5),
                      Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(11)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
