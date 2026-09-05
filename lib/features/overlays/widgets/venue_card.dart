import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// كارت ملعب في شاشة الحجز: اسم + سعر + تفاصيل + شريط امتلاء + زر حجز.
class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.name,
    required this.price,
    required this.meta,
    required this.fillLabel,
    required this.fill, // 0..1
    required this.action,
    this.full = false,
    this.topBorder = true,
  });

  final String name;
  final String price;
  final String meta;
  final String fillLabel;
  final double fill;
  final String action;
  final bool full;
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    final labelColor = full ? AppColors.neutral700 : AppColors.accent700;
    final barColor = full ? AppColors.neutral500 : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: topBorder
            ? const Border(top: BorderSide(color: AppColors.divider, width: 2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(name, style: AppText.h(15))),
              Text(price, style: AppText.h(14)),
              Text('/س', style: AppText.body(9, color: AppColors.neutral700)),
            ],
          ),
          const SizedBox(height: 2),
          Text(meta, style: AppText.body(11, color: AppColors.neutral700)),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(fillLabel, style: AppText.h(10, color: labelColor)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 6,
                  color: AppColors.neutral300,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: fill,
                      child: Container(color: barColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: full ? AppColors.divider : AppColors.black,
                    width: 2,
                  ),
                ),
                child: Text(action,
                    style: AppText.h(11, color: full ? AppColors.neutral600 : AppColors.ink)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
