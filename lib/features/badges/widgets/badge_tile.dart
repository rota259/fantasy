import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../data/badge_catalog.dart';
import '../../../core/widgets/motion.dart';

/// شارة جوه خماسي بلون المستوى. السرّية اللي لسه ماتاخدتش بتظهر "؟".
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.def, required this.tier, this.size = 58, this.onTap, this.showName = true});

  final BadgeDef def;
  final int tier;
  final double size;
  final VoidCallback? onTap;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final earned = tier > 0;
    final hidden = def.secret && !earned;
    return Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: earned ? 1 : 0.45,
            child: PentagonIcon(
              size: size,
              fill: earned ? AppColors.black : AppColors.neutral100,
              stroke: BadgeCatalog.tierColors[tier.clamp(0, 3)],
              strokeWidth: earned ? 3 : 2,
              child: Text(hidden ? '؟' : def.emoji, style: TextStyle(fontSize: size * 0.34)),
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 4),
            Text(hidden ? 'سرّية' : def.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(10)),
            if (earned)
              Text(
                BadgeCatalog.tierNames[tier.clamp(0, 3)],
                style: AppText.body(9, color: BadgeCatalog.tierColors[tier.clamp(0, 3)]),
              ),
          ],
        ],
      ),
    );
  }
}
