import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../players/data/models/player.dart';
import '../data/models/player_rating.dart';
import '../../../core/widgets/motion.dart';

/// صف لاعب في التقييم: الصورة + المتوسط + أرقام ١..١٠ للتقييم.
class RatingRow extends StatelessWidget {
  const RatingRow({super.key, required this.player, required this.rating, required this.leader, this.onRate});

  final Player player;
  final PlayerRating? rating;
  final bool leader; // الأعلى تقييمًا دلوقتي
  final ValueChanged<int>? onRate; // null = التقييم مقفول

  @override
  Widget build(BuildContext context) {
    final r = rating;
    return Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: AppDecor.tile.copyWith(color: leader ? AppColors.accent100 : AppColors.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PentagonAvatar(initials: player.initials, photoUrl: player.imageUrl, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${player.name}${leader ? '  ⭐' : ''}', style: AppText.h(14)),
                    Text('${player.team} · ${player.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(r?.avg?.toStringAsFixed(1) ?? '—', style: AppText.h(20, color: AppColors.accent)),
                  Text('${r?.votes ?? 0} صوت', style: AppText.body(9, color: AppColors.neutral600)),
                ],
              ),
            ],
          ),
          if (onRate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (var v = 1; v <= 10; v++)
                  Expanded(
                    child: Pressable(
                      onTap: () => onRate!(v),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.md,
                          color: r?.mine == v ? AppColors.black : null,
                          border: Border.all(color: AppColors.line, width: 1.2),
                        ),
                        child: Text('$v', style: AppText.h(11, color: r?.mine == v ? AppColors.white : AppColors.ink)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
