part of 'venue_requests_screen.dart';

extension _VenueRequestsScreenStateSections1 on _VenueRequestsScreenState {
  void _reload() {
    if (mounted) {
      _update(() {
        _future = _repo.forOwner(widget.ownerId);
      });
    }
  }

  Future<void> _set(Booking b, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    _update(() => _busy.add(b.id));
    try {
      await _repo.setStatus(b.id, status);
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (status) {
            'confirmed' => 'اتأكد الحجز واتبعت إشعار للحاجز',
            'rejected' => 'اترفض الطلب واتبعت إشعار للحاجز',
            _ => 'اتلغى الحجز',
          }),
        ),
      );
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر التحديث: $e')));
    } finally {
      if (mounted) _update(() => _busy.remove(b.id));
    }
  }

  Widget _row(Booking b) {
    final busy = _busy.contains(b.id);
    final phone = b.userPhone;
    return Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: AppDecor.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('${b.venueName ?? ''} · ${slotText(b.day, b.hour)}', style: AppText.h(14))),
              Text(b.statusLabel, style: AppText.body(11, color: AppColors.neutral700)),
            ],
          ),
          Text(
            '${b.userName ?? 'يوزر'}${phone != null ? ' · $phone' : ''}',
            style: AppText.body(12, color: AppColors.neutral700),
          ),
          if (b.note != null) Text('«${b.note}»', style: AppText.body(12)),
          if (!b.isPast && b.isActive) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (phone != null) _btn('اتصل', AppColors.black, busy ? null : () => Launchers.call(phone)),
                if (b.isPending) ...[
                  _btn('أكّد', AppColors.accent, busy ? null : () => _set(b, 'confirmed')),
                  _btn('ارفض', AppColors.danger, busy ? null : () => _set(b, 'rejected')),
                ] else
                  _btn('إلغاء الحجز', AppColors.danger, busy ? null : () => _set(b, 'cancelled')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback? onTap) => Expanded(
    child: Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: onTap == null ? AppColors.neutral500 : color, borderRadius: AppRadius.md),
        padding: const EdgeInsets.all(10),
        alignment: Alignment.center,
        child: Text(label, style: AppText.h(12, color: AppColors.white)),
      ),
    ),
  );
}
