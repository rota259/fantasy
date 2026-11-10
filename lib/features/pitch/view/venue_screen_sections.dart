part of 'venue_screen.dart';

extension _VenueScreenStateSections1 on _VenueScreenState {
  Future<void> _load() async {
    try {
      final list = await _repo.forVenue(v.id, dayOffset(0), dayOffset(bookingDaysAhead - 1));
      if (!mounted) return;
      _update(() {
        _bookings = list;
        _loading = false;
        // لو الميعاد المختار اتحجز من حد تاني نلغي الاختيار
        if (_hour != null && list.any((b) => b.hour == _hour && sameDay(b.day, dayOffset(_day)))) _hour = null;
      });
    } catch (_) {
      if (mounted) _update(() => _loading = false);
    }
  }

  Future<void> _book() async {
    final hour = _hour;
    if (hour == null) return;
    final day = dayOffset(_day);
    final note = await showBookingConfirmSheet(context, v, day, hour);
    if (note == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    _update(() => _sending = true);
    try {
      await _repo.request(venueId: v.id, userId: widget.userId, day: day, hour: hour, note: note);
      _update(() => _hour = null);
      await _load();
      if (mounted) await showBookingSentSheet(context, v, day, hour);
    } on SlotTakenException {
      messenger.showSnackBar(const SnackBar(content: Text('الميعاد ده لسه اتحجز من حد تاني — اختار ميعاد تاني')));
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر إرسال الطلب: $e')));
    } finally {
      if (mounted) _update(() => _sending = false);
    }
  }

  Widget _info() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(v.name, style: AppText.h(20))),
            Text('${v.price} جنيه/ساعة', style: AppText.h(14, color: AppColors.accent)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${v.surface} · مفتوح ${formatHour(v.openHour)} لـ ${formatHour(v.closeHour)}${v.feature != null ? ' · ${v.feature}' : ''}',
          style: AppText.body(12, color: AppColors.neutral700),
        ),
        if (v.address != null) Text(v.address!, style: AppText.body(12, color: AppColors.neutral700)),
      ],
    ),
  );
}
