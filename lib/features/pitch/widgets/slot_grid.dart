import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/widgets/match_format.dart';
import '../data/models/booking.dart';
import '../data/models/venue.dart';

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

  String _dayLabel(int i) {
    final d = dayOffset(i);
    if (i == 0) return 'النهارده';
    if (i == 1) return 'بكرة';
    return '${arabicWeekday(d)} ${d.day}/${d.month}';
  }

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
                GestureDetector(
                  onTap: () => onDay(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == dayIndex ? AppColors.black : null,
                      border: Border.all(color: AppColors.black, width: 2),
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

  Widget _slot(int h, DateTime day, DateTime now) {
    Booking? b;
    for (final x in bookings) {
      if (x.hour == h && sameDay(x.day, day)) b = x;
    }
    final past = slotStart(day, h).isBefore(now);
    final mine = b != null && b.userId == userId;
    final selected = selectedHour == h && b == null && !past;

    final (Color color, String label) = past
        ? (AppColors.neutral400, 'فات')
        : b == null
        ? (AppColors.accent, 'متاح')
        : b.isConfirmed
        ? (AppColors.danger, mine ? 'حجزك ✅' : 'محجوز')
        : (const Color(0xFFCA8A04), mine ? 'طلبك ⏳' : 'معلّق');

    return GestureDetector(
      onTap: (past || b != null) ? null : () => onPick(h),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : null,
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Text(formatHour(h), style: AppText.h(14, color: selected ? AppColors.white : AppColors.ink)),
            Text(selected ? 'اخترته ✓' : label, style: AppText.body(10, color: selected ? AppColors.white : color)),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(border: Border.all(color: c, width: 2)),
      ),
      const SizedBox(width: 4),
      Text(t, style: AppText.body(10, color: AppColors.neutral700)),
    ],
  );
}
