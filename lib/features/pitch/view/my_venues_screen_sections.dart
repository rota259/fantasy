part of 'my_venues_screen.dart';

extension _MyVenuesScreenStateSections1 on _MyVenuesScreenState {
  Future<void> _open([Venue? v]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VenueFormScreen(userId: widget.userId, editing: v),
      ),
    );
    if (saved != true || !mounted) return;
    _reload();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(v == null ? 'اتضاف ملعبك ✓ — بقى ظاهر لكل الناس' : 'اتعدّل الملعب ✓')));
  }

  Future<void> _delete(Venue v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('حذف الملعب', style: AppText.h(16)),
        content: Text('متأكد إنك عايز تحذف «${v.name}»؟ كل حجوزاته وتقييماته هتتمسح.', style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('احذف', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.deleteVenue(v.id);
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Widget _row(Venue v) => Pressable(
    behavior: HitTestBehavior.opaque,
    onTap: () => _open(v),
    child: Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: AppDecor.tile,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: v.photos.isEmpty
                ? Container(color: AppColors.neutral200, child: const Icon(Icons.stadium_outlined))
                : NetImage(v.photos.first, fallback: Container(color: AppColors.neutral200)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name, style: AppText.h(14)),
                Text(
                  '${v.price}ج/ساعة · ${formatHour(v.openHour)} لـ ${formatHour(v.closeHour)}',
                  style: AppText.body(10, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          Pressable(
            onTap: () => _delete(v),
            child: Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            ),
          ),
        ],
      ),
    ),
  );
}
