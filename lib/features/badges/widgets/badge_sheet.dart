import 'package:flutter/material.dart';

import '../../../core/share/share_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../data/badge_catalog.dart';
import '../data/models/user_badge.dart';
import 'badge_tile.dart';
import '../../../core/widgets/motion.dart';

/// تفاصيل شارة: المستويات + التقدّم + مشاركة (لو اتاخدت).
Future<void> showBadgeSheet(BuildContext context, BadgeDef def, UserBadge? mine, String userName) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => _BadgeSheet(def: def, mine: mine, userName: userName),
  );
}

class _BadgeSheet extends StatelessWidget {
  _BadgeSheet({required this.def, required this.mine, required this.userName});

  final BadgeDef def;
  final UserBadge? mine;
  final String userName;
  final _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final tier = mine?.tier ?? 0;
    final hidden = def.secret && tier == 0;
    final next = def.nextTarget(tier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: Container(
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: AppRadius.md),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    BadgeTile(def: def, tier: tier, size: 76, showName: false),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hidden ? 'شارة سرّية 🤫' : def.name, style: AppText.h(20)),
                          Text(
                            tier > 0 ? '${BadgeCatalog.tierNames[tier]} · $userName' : 'لسه',
                            style: AppText.h(12, color: BadgeCatalog.tierColors[tier]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hidden ? 'هتعرفها لما تاخدها' : def.describe(tier == 0 ? 0 : tier - 1),
                            style: AppText.body(12, color: AppColors.neutral700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!hidden) ...[
              const SizedBox(height: 14),
              for (var t = 0; t < def.tiers.length; t++) _tierRow(t, tier),
              if (next != null && !def.lowerIsBetter) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: ((mine?.value ?? 0) / next).clamp(0, 1).toDouble(),
                  color: AppColors.accent,
                  backgroundColor: AppColors.neutral200,
                ),
                const SizedBox(height: 4),
                Text(
                  '${mine?.value ?? 0} من $next للمستوى الجاي',
                  style: AppText.body(11, color: AppColors.neutral600),
                ),
              ],
            ],
            if (tier > 0) ...[
              const SizedBox(height: 16),
              Pressable(
                onTap: () =>
                    ShareCard.share(_cardKey, 'خدت شارة «${def.name}» ${BadgeCatalog.tierNames[tier]} في الخماسي 🏅'),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.center,
                  child: Text('شيّرها', style: AppText.h(14, color: AppColors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tierRow(int t, int tier) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Container(width: 12, height: 12, color: BadgeCatalog.tierColors[t + 1]),
        const SizedBox(width: 8),
        Expanded(child: Text('${BadgeCatalog.tierNames[t + 1]}: ${def.describe(t)}', style: AppText.body(12))),
        if (tier > t) Icon(Icons.check, size: 16, color: AppColors.accent),
      ],
    ),
  );
}
