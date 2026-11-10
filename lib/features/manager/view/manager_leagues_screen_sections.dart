part of 'manager_leagues_screen.dart';

extension _ManagerLeaguesScreenStateSections1 on _ManagerLeaguesScreenState {
  /// الدوري العام: كل اليوزرز أوتوماتيك بترتيب النقط (والتعادل بالامتلاك الأقل).
  Future<void> _createGlobal() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.createGlobalLeague('دوري الخماسي العام');
      _reload();
      messenger.showSnackBar(const SnackBar(content: Text('اتعمل الدوري العام واتبعت إشعار للكل ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Future<void> _delete(League l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('حذف الدوري', style: AppText.h(16)),
        content: Text(
          '«${l.name}» بتاع ${l.ownerName ?? '—'} — ${l.memberCount} عضو هيخرجوا منه.',
          style: AppText.body(13),
        ),
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
      await _repo.deleteLeague(l.id);
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Widget _row(League l) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: AppDecor.softDivider,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.name, style: AppText.h(14)),
              Text(
                l.isGlobal
                    ? 'العام · كل اليوزرز أوتوماتيك'
                    : '${l.typeLabel} · ${l.memberCount} عضو · صاحبه: ${l.ownerName ?? '—'}',
                style: AppText.body(10, color: AppColors.neutral700),
              ),
            ],
          ),
        ),
        if (!l.isGlobal)
          Pressable(
            onTap: () {
              Clipboard.setData(ClipboardData(text: l.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اتنسخ الكود ✓')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
              child: Text(l.inviteCode, style: AppText.h(12, color: AppColors.white, spacingEm: 0.1)),
            ),
          ),
        const SizedBox(width: 10),
        Pressable(
          onTap: () => _delete(l),
          child: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
        ),
      ],
    ),
  );
}
