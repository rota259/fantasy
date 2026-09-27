import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../players/data/availability.dart';
import '../../players/data/models/player.dart';
import '../../players/widgets/availability_badge.dart';
import '../../../core/widgets/motion.dart';

/// ترويسة اللاعب السوداء (أفاتار + اسم + مركز) — بيانات اللاعب الحقيقية.
class PlayerHeader extends StatelessWidget {
  const PlayerHeader({super.key, required this.onBack, required this.player});
  final VoidCallback onBack;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: onBack,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: Text('‹', style: AppText.h(16, color: AppColors.white)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              PentagonAvatar(
                initials: player.initials,
                photoUrl: player.imageUrl,
                size: 70,
                verified: player.isVerified,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.h(24, color: AppColors.white, height: 1),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${player.team} · ${player.positionAr}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        AvailabilityBadge(player.availability, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            player.availability != Availability.ready && player.news?.isNotEmpty == true
                                ? '${Availability.statusLine(player.availability)} · ${player.news}'
                                : Availability.statusLine(player.availability),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.h(11, color: Availability.color(player.availability)),
                          ),
                        ),
                      ],
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

/// شبكة 3×2 لإحصائيات اللاعب الحقيقية (من جدول players).
class PlayerStatGrid extends StatelessWidget {
  const PlayerStatGrid({super.key, required this.player});
  final Player player;

  List<(String, String, bool)> get _stats => [
    ('${player.totalPoints}', 'إجمالي النقاط', false),
    (player.form.toStringAsFixed(1), 'الفورمة', true),
    ('${player.goals}', 'أهداف', false),
    ('${player.assists}', 'صناعة', false),
    ('${player.cleanSheets}', 'شباك نظيفة', false),
    ('${player.yellowCards}', 'كروت صفرا', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.7,
        children: _stats.map((s) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.divider),
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.$1, style: AppText.h(22, color: s.$3 ? AppColors.accent : AppColors.ink)),
                Text(s.$2, style: AppText.body(9, color: AppColors.neutral700)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
