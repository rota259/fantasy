part of 'admin_betting_screen.dart';

extension _AdminBettingScreenStateSections1 on _AdminBettingScreenState {
  Future<void> _set(BettingReport r, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    // «اتثبت» = بان نهائي → تأكيد الأول
    if (status == 'proven') {
      final direct = r.suspectUserId != null;
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: AppColors.bg,
          title: Text('اتثبت إنه بيراهن؟', style: AppText.h(16)),
          content: Text(
            direct
                ? 'حساب «${r.suspect}» هياخد بان نهائي من الأبلكيشن دلوقتي.'
                : 'البلاغ ده مكتوب بالاسم بس (مش على حساب بعينه) — بعد التأكيد افتح «المستخدمين» ووقّف الحساب بنفسك.',
            style: AppText.body(13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(direct ? 'بان نهائي' : 'اتثبت', style: AppText.h(13, color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    try {
      final banned = await _repo.setStatus(r.id, status);
      if (!mounted) return;
      _update(() => _future = _repo.adminReports());
      if (status != 'proven') return;
      messenger.showSnackBar(
        banned
            ? SnackBar(content: Text('«${r.suspect}» خد بان نهائي ⛔'))
            : SnackBar(
                content: const Text('اتثبت — وقّف الحساب من «المستخدمين»'),
                action: SnackBarAction(
                  label: 'المستخدمين',
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerUsersScreen())),
                ),
              ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Widget _card(BettingReport r) {
    final (label, color) = _AdminBettingScreenState._labels[r.status] ?? ('—', AppColors.neutral500);
    final closed = r.status == 'proven' || r.status == 'dismissed';
    return Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('على: ${r.suspect}', style: AppText.h(14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: AppRadius.sm),
                child: Text(label, style: AppText.h(10, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(r.details, style: AppText.body(13)),
          const SizedBox(height: 6),
          Text(
            'من ${r.reporter} · ${r.zone} · ${r.createdAt.day}/${r.createdAt.month}',
            style: AppText.body(11, color: AppColors.neutral700),
          ),
          if (r.suspectUserId != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                r.suspectBanned ? 'الحساب موقوف' : 'البلاغ على حساب بعينه — «اتثبت» بتوقّفه على طول',
                style: AppText.h(11, color: r.suspectBanned ? AppColors.danger : AppColors.accent),
              ),
            ),
          if (!closed)
            Wrap(
              spacing: 8,
              children: [
                if (r.status == 'open')
                  TextButton(onPressed: () => _set(r, 'investigating'), child: const Text('بحقّق')),
                TextButton(
                  onPressed: () => _set(r, 'proven'),
                  child: Text(
                    r.suspectUserId != null ? 'اتثبت + بان' : 'اتثبت',
                    style: AppText.h(13, color: AppColors.danger),
                  ),
                ),
                TextButton(onPressed: () => _set(r, 'dismissed'), child: const Text('مش صحيح')),
              ],
            ),
        ],
      ),
    );
  }
}
