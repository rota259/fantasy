import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/widgets/match_format.dart';
import '../data/models/booking.dart';
import '../data/models/venue.dart';
import '../../../core/widgets/motion.dart';

part 'slot_grid_sections.dart';

/// عدد الأيام اللي ينفع تحجز فيها قدّام.
const bookingDaysAhead = 7;

DateTime dayOffset(int i) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + i);
}

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// تابات الأيام + مواعيد اليوم: متاح / محجوز / معلّق / فات.
class SlotGrid extends StatelessWidget {
  const SlotGrid({
    super.key,
    required this.venue,
    required this.bookings,
    required this.userId,
    required this.dayIndex,
    required this.selectedHour,
    required this.onDay,
    required this.onPick,
  });

  final Venue venue;
  final List<Booking> bookings; // الفعّالة (معلّقة/مؤكدة)
  final String userId;
  final int dayIndex;
  final int? selectedHour;
  final ValueChanged<int> onDay;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final day = dayOffset(dayIndex);
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (var i = 0; i < bookingDaysAhead; i++)
                Pressable(
                  onTap: () => onDay(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.md,
                      color: i == dayIndex ? AppColors.black : null,
                      border: Border.all(color: AppColors.line, width: 1.2),
                    ),
                    child: Text(
                      _dayLabel(i),
                      style: AppText.h(12, color: i == dayIndex ? AppColors.white : AppColors.ink),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [for (final h in venue.hours) _slot(h, day, now)]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legend(AppColors.accent, 'متاح'),
              _legend(const Color(0xFFCA8A04), 'معلّق'),
              _legend(AppColors.danger, 'محجوز'),
              _legend(AppColors.neutral400, 'فات'),
            ],
          ),
        ),
      ],
    );
  }
}
