part of 'manager_venues_screen.dart';

extension _ManagerVenuesScreenStateSections1 on _ManagerVenuesScreenState {
  Future<void> _open([Venue? v]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VenueFormScreen(userId: context.read<AuthCubit>().state.user?.id ?? '', editing: v, isManager: true),
      ),
    );
    if (saved == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(v == null ? 'اتضاف الملعب ✓' : 'اتعدّل الملعب ✓')));
      }
    }
  }

  Future<void> _delete(Venue v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('حذف الملعب', style: AppText.h(16)),
        content: Text('متأكد إنك عايز تحذف «${v.name}»؟ كل حجوزاته هتتمسح.', style: AppText.body(13)),
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
      messenger.showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
    }
  }

  /// توثيق الملعب: صاحبه يقدر يعمل بطولات ويعلن لأهل منطقته.
  Future<void> _verify(Venue v) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.verify(v.id, !v.verified);
      _reload();
      messenger.showSnackBar(
        SnackBar(content: Text(v.verified ? 'اتشال التوثيق' : 'اتوثّق الملعب ✓ — وصل لصاحبه إشعار')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _row(Venue v) {
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(v),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: AppDecor.tile,
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
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
                  Text(
                    [
                      if (!v.hasAnyLocation) 'من غير موقع' else if (!v.hasLocation) 'لينك بس (مش ظاهر على الخريطة)',
                      v.ownerId == null ? 'الإدارة بيأكّد الحجز' : 'ليه صاحب',
                      if (kVenueVerify && !v.verified && v.verifyRequestedAt != null) '⏳ طالب توثيق',
                    ].join(' · '),
                    style: AppText.body(10, color: v.hasAnyLocation ? AppColors.neutral600 : AppColors.danger),
                  ),
                ],
              ),
            ),
            if (kVenueVerify)
              Pressable(
                onTap: () => _verify(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: v.verified ? AppColors.accent : null,
                    borderRadius: AppRadius.sm,
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Text(
                    v.verified ? 'موثّق ✓' : 'وثّق',
                    style: AppText.h(11, color: v.verified ? AppColors.white : AppColors.accent),
                  ),
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
}
