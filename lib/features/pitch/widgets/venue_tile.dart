import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/models/booking.dart';
import '../data/models/venue.dart';

/// كارت ملعب في القايمة: صورة + اسم + سعر + مواعيد + عنوان.
class VenueTile extends StatelessWidget {
  const VenueTile({super.key, required this.venue, required this.onTap});

  final Venue venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = venue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 140,
            child: v.photos.isEmpty
                ? Container(
                    color: AppColors.night2,
                    child: const Icon(Icons.stadium_outlined, size: 48, color: AppColors.white),
                  )
                : Image.network(v.photos.first, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.night2)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.name, style: AppText.h(16)),
                  const SizedBox(height: 2),
                  Text('${formatHour(v.openHour)} لـ ${formatHour(v.closeHour)}${v.feature != null ? ' · ${v.feature}' : ''}',
                      style: AppText.body(11, color: AppColors.neutral700)),
                  if (v.address != null)
                    Text(v.address!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: AppText.body(11, color: AppColors.neutral600)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.accent,
                child: Text('${v.price}ج/س', style: AppText.h(13, color: AppColors.white)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
