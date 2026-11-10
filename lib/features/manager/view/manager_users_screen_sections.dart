part of 'manager_users_screen.dart';

extension _ManagerUsersScreenStateSections1 on _ManagerUsersScreenState {
  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      _update(() {
        _future = _load();
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Future<void> _toggle(AppUser u) async {
    final toManager = !u.isOrganizer;
    final ok = await confirmDialog(
      context,
      toManager ? 'خلّيه مدير منطقة؟' : 'رجّعه يوزر عادي؟',
      toManager
          ? '«${u.name}» هيدير فرقه وماتشاته في منطقته بس. حسابه هيبقى حساب شغل: مش هيلعب فانتازي '
                'ولا يصوّت، وهيخرج من الدوريات.'
          : '«${u.name}» مش هيقدر يعمل ماتشات أو فرق تاني.',
    );
    if (!ok || !mounted) return;
    await _run(() => _repo.setRole(u.id, toManager ? 'organizer' : 'user'), 'اتغيّر الدور ✓');
  }

  Future<void> _ban(AppUser u) async {
    final ban = u.isActive;
    final ok = await confirmDialog(
      context,
      ban ? 'حظر «${u.name}»؟' : 'فك حظر «${u.name}»؟',
      ban
          ? 'هيقدر يتفرّج بس: مش هيعمل تشكيلة ولا يصوّت ولا يعلّق ولا يحجز، ومش هيظهر في الترتيب.'
          : 'هيرجع يستخدم الأبلكيشن عادي.',
    );
    if (!ok || !mounted) return;
    await _run(() => _repo.setActive(u.id, !ban), ban ? 'اتحظر ✓' : 'اتفك الحظر ✓');
  }

  /// المحدّدين: رجّع المديرين يوزرز · امسح الحسابات (الكل لازم يكتب "امسح").
  Future<void> _bulk(List<AppUser> users, {required bool delete, bool all = false}) async {
    final ids = [for (final u in users) u.id];
    final organizers = [
      for (final u in users)
        if (u.isOrganizer) u.id,
    ];
    final ok = await confirmBulk(
      context,
      delete ? 'مسح ${ids.length} حساب' : 'رجّع ${organizers.length} مدير يوزرز',
      delete
          ? 'الحسابات دي هتتمسح خالص بكل بياناتها (تشكيلات · نقط · فرق المديرين تفضل من غير صاحب). مفيش رجوع.'
          : 'مش هيقدروا يعملوا ماتشات أو فرق تاني.',
      typeToConfirm: delete && all ? 'امسح' : null,
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final n = delete ? await _repo.deleteUsers(ids) : await _repo.demoteOrganizers(organizers);
      if (mounted) _update(() => _sel = null);
      if (n == 0) throw StateError('ولا حاجة اتغيّرت');
    }, delete ? 'اتمسحت الحسابات ✓' : 'رجعوا يوزرز ✓');
  }

  Widget _filter(String label, String? role) {
    final on = _role == role;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Pressable(
        onTap: () => _update(() {
          _role = role;
          _sel = null;
          _future = _load();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? AppColors.accent : null,
            borderRadius: AppRadius.md,
            border: Border.all(color: on ? AppColors.accent : AppColors.line),
          ),
          child: Text(label, style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
        ),
      ),
    );
  }

  /// الضغط على يوزر = تشكيلته في الجولة (للفرجة بس).
  Widget _row(AppUser u, Zone? zone) {
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: u.isOrganizer || u.isManager
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveRoundScreen(userId: u.id, ownerName: u.name),
              ),
            ),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: AppDecor.tile,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.isActive ? u.name : '${u.name} · محظور', style: AppText.h(14)),
                  Text(
                    '${zone?.label ?? 'من غير منطقة'} · ${u.phone ?? u.email}',
                    style: AppText.body(10, color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            if (u.isManager || u.isOrganizer)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: u.isManager ? AppColors.accent : AppColors.info,
                  borderRadius: AppRadius.sm,
                ),
                child: Text(u.isManager ? 'أدمن' : 'مدير', style: AppText.h(10, color: AppColors.white)),
              ),
            // الأدمن مبيتغيّرش من التطبيق
            if (!u.isManager) ...[
              _btn(u.isActive ? 'حظر' : 'فك', () => _ban(u)),
              if (u.isOrganizer) _btn('انقله', () => _move(u)),
              if (u.isActive) _btn('مشرف', () => _supervise(u)),
              _btn(u.isOrganizer ? 'رجّعه يوزر' : 'خلّيه مدير', () => _toggle(u)),
            ],
          ],
        ),
      ),
    );
  }
}
