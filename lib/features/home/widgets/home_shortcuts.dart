import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';

/// مختصر في الهوم: أيقونة + اسم + اللي بيحصل لما يتداس.
typedef HomeShortcut = ({IconData icon, String label, VoidCallback onTap});

/// المختصرات في صفّين ثابتين (٤ في الصف) — كل واحد مربع ناعم بأيقونة واحدة الستايل.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key, required this.items});

  final List<HomeShortcut> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مختصرات', style: AppText.kicker()),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.86,
            children: [
              for (final it in items)
                Pressable(
                  behavior: HitTestBehavior.opaque,
                  onTap: it.onTap,
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(it.icon, size: 24, color: AppColors.accent),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        it.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppText.h(11),
                      ),
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
