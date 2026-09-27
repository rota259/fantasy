import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../data/models/booking.dart';
import '../data/models/venue.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/motion.dart';

/// كارت ملعب في القايمة: صورة + اسم + تقييم + سعر + مواعيد + عنوان.
class VenueTile extends StatelessWidget {
  const VenueTile({super.key, required this.venue, required this.onTap, this.rating});

  final Venue venue;
  final VoidCallback onTap;
  final ({double avg, int count})? rating;

  @override
  Widget build(BuildContext context) {
    final v = venue;
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 140,
              child: v.photos.isEmpty
                  ? Container(
                      color: AppColors.night2,
                      child: Icon(Icons.stadium_outlined, size: 48, color: AppColors.white),
                    )
                  : NetImage(v.photos.first, fallback: Container(color: AppColors.night2)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name, style: AppText.h(16)),
                        Text(
                          rating == null
                              ? 'لسه محدش قيّمه'
                              : '★ ${rating!.avg.toStringAsFixed(1)} (${rating!.count} تقييم)',
                          style: AppText.h(11, color: rating == null ? AppColors.neutral500 : AppColors.gold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatHour(v.openHour)} لـ ${formatHour(v.closeHour)}${v.feature != null ? ' · ${v.feature}' : ''}',
                          style: AppText.body(11, color: AppColors.neutral700),
                        ),
                        if (v.address != null)
                          Text(
                            v.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(11, color: AppColors.neutral600),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                    child: Text('${v.price}ج/س', style: AppText.h(13, color: AppColors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
