import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../week/data/models/week_player.dart';

/// نجم الجولة: أعلى لاعب نقط في منطقتي في آخر تشكيلة جولة اعتمدتها الإدارة (بيفضل لحد اللي بعدها).
class StarOfWeekCard extends StatelessWidget {
  const StarOfWeekCard({
    super.key,
    required this.star,
    required this.isFinal,
    required this.fromPrevious,
    required this.label,
  });

  final WeekPlayer? star;
  final bool isFinal;
  final bool fromPrevious; // الجولة الجديدة لسه مفيهاش نقط → بنعرض نجم اللي فاتت
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = star;
    final badge = fromPrevious ? 'الجولة اللي فاتت' : (isFinal ? 'النهائي ✓' : '● مباشر');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Container(
        decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
        padding: const EdgeInsets.all(16),
        child: p == null
            ? Row(
                children: [
                  PentagonIcon(
                    size: 64,
                    fill: AppColors.night,
                    stroke: AppColors.neutral600,
                    child: Icon(Icons.star_outline, color: AppColors.neutral400),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'نجم الجولة\nبيظهر أول ما الإدارة تعتمد تشكيلة الجولة',
                      style: AppText.h(14, color: AppColors.white),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: 92, verified: p.verified),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('⭐ نجم الجولة', style: AppText.kicker(color: AppColors.accent400)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isFinal || fromPrevious ? AppColors.accent : AppColors.danger,
                                borderRadius: AppRadius.sm,
                              ),
                              child: Text(badge, style: AppText.h(9, color: AppColors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.h(22, color: AppColors.white),
                        ),
                        Text(
                          '${p.team} · ${p.positionAr}',
                          style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(9, color: AppColors.neutral400),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('${p.points}', style: AppText.h(40, color: AppColors.accent400, height: 1)),
                      Text('نقطة', style: AppText.body(10, color: AppColors.white)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
