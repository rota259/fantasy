part of 'my_bookings_screen.dart';

extension _MyBookingsScreenStateSections1 on _MyBookingsScreenState {
  void _reload() {
    if (mounted) {
      _update(() {
        _future = _repo.mine(widget.userId);
      });
    }
  }

  Future<void> _cancel(Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('إلغاء الحجز', style: AppText.h(16)),
        content: Text('تلغي حجز ${b.venueName ?? ''} يوم ${slotText(b.day, b.hour)}؟', style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لأ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('ألغي', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setStatus(b.id, 'cancelled');
      _reload();
      messenger.showSnackBar(const SnackBar(content: Text('اتلغى الحجز')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر الإلغاء: $e')));
    }
  }

  Widget _row(Booking b) {
    final canCancel = b.isActive && !b.isPast;
    return Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: AppDecor.tile,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.venueName ?? 'ملعب', style: AppText.h(14)),
                Text(slotText(b.day, b.hour), style: AppText.body(12, color: AppColors.neutral700)),
                Text(b.statusLabel, style: AppText.h(12, color: _color(b.status))),
              ],
            ),
          ),
          if (canCancel)
            Pressable(
              onTap: () => _cancel(b),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.danger, width: 2),
                ),
                child: Text('إلغاء', style: AppText.h(11, color: AppColors.danger)),
              ),
            ),
        ],
      ),
    );
  }

  Color _color(String s) => switch (s) {
    'confirmed' => AppColors.accent,
    'pending' => const Color(0xFFCA8A04),
    'rejected' => AppColors.danger,
    _ => AppColors.neutral600,
  };
}
