part of 'slot_grid.dart';

extension _SlotGridSections1 on SlotGrid {
  String _dayLabel(int i) {
    final d = dayOffset(i);
    if (i == 0) return 'النهارده';
    if (i == 1) return 'بكرة';
    return '${arabicWeekday(d)} ${d.day}/${d.month}';
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
        ? (AppColors.danger, mine ? 'حجزك' : 'محجوز')
        : (const Color(0xFFCA8A04), mine ? 'طلبك' : 'معلّق');

    return Pressable(
      onTap: (past || b != null) ? null : () => onPick(h),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
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
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: c, width: 2),
        ),
      ),
      const SizedBox(width: 4),
      Text(t, style: AppText.body(10, color: AppColors.neutral700)),
    ],
  );
}
