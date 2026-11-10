part of 'tournament_matches_tab.dart';

extension _TournamentMatchesTabSections2 on TournamentMatchesTab {
  /// المنظّم بيختار اليوم والساعة → الميعاد بيتحفظ وأهل المنطقة بيوصلهم إشعار.
  Future<void> _pickTime(BuildContext context, GameMatch m) async {
    final cubit = context.read<TournamentCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final start = m.timeSet && m.dateTime.isAfter(now) ? m.dateTime : now.add(const Duration(hours: 2));
    final day = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      helpText: '${m.teamA} ضد ${m.teamB}',
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
    if (time == null) return;
    if (!context.mounted) return;
    final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    // المدة (الافتراضي ساعة) — الماتش بيتقفل لوحده بعدها
    var duration = m.durationMin;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          backgroundColor: AppColors.bg,
          title: Text('مدة الماتش', style: AppText.h(16)),
          content: DurationChips(value: duration, onChanged: (d) => set(() => duration = d)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('تمام')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final err = await cubit.setMatchTime(m.id, at, duration);
    messenger.showSnackBar(
      SnackBar(content: Text(err ?? 'اتحدد الميعاد ✓ ${arabicWeekday(at)} ${at.day}/${at.month} ${arabicTime(at)}')),
    );
  }
}
