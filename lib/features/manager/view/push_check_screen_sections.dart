part of 'push_check_screen.dart';

extension _PushCheckScreenStateSections1 on _PushCheckScreenState {
  Future<void> _load() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      _allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      _allowed = false;
    }
    try {
      final d = await _repo.pushDiagnostics();
      if (mounted) {
        _update(() {
          _d = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) _update(() => _error = dbMessage(e, fallback: 'شغّل ملف الداتابيز (قسم 46) وجرّب تاني'));
    }
  }

  Future<void> _do(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    _update(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
    await _load();
    if (mounted) _update(() => _busy = false);
  }

  Widget _body(Map<String, dynamic> d) {
    final url = d['push_url'] as String?;
    final last = ((d['last'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final lastOk = last.isNotEmpty && last.first['status'] == 200 && !_PushCheckScreenState._fcmFailed(last.first);
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            'عشان الإشعار يوصل ويعمل صوت والأبلكيشن مقفول، الخمسة دول لازم يبقوا ✓',
            style: AppText.body(12, color: AppColors.neutral700),
          ),
        ),
        _check(
          'إذن الإشعارات على الموبايل ده',
          _allowed == true,
          fix: 'الموبايل مانع الإشعارات عن الأبلكيشن',
          action: ('اطلب الإذن', _askPermission),
        ),
        _check(
          'الجهاز ده متسجّل (${d['tokens'] ?? 0} جهاز متسجّل في الكل)',
          d['my_token'] == true,
          fix: 'الأبلكيشن مسجّلش الجهاز — غالبًا النت كان واقع وقت الدخول',
          action: ('سجّل الجهاز', _registerToken),
        ),
        _check(
          'إضافة pg_net في الداتابيز',
          d['pg_net'] == true,
          fix: 'من لوحة Supabase: Database ← Extensions ← فعّل pg_net ← وشغّل ملف الداتابيز تاني',
        ),
        _check(
          'رابط فانكشن الإشعارات',
          url == _expectedUrl,
          fix: url == null ? 'الداتابيز متعرفش تبعت لمين — دوس الزرار' : 'الرابط المتسجّل لمشروع تاني:\n$url',
          action: ('ظبّط الرابط', () => _do(() => _repo.setPushUrl(_expectedUrl), 'الرابط اتظبط ✓')),
        ),
        _check(
          'الفانكشن بترد صح',
          lastOk,
          fix: last.isEmpty ? 'مفيش محاولات لسه — ابعت إشعار تجربة' : _PushCheckScreenState._explain(last.first),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: FilledButton.icon(
            onPressed: _busy ? null : _test,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(_busy ? 'لحظة…' : 'ابعتلي إشعار تجربة'),
          ),
        ),
        if (last.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text('آخر محاولات', style: AppText.kicker(color: AppColors.accent)),
          ),
          for (final r in last)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                '${r['status'] ?? '—'} · ${r['error'] ?? r['body'] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: AppText.body(11, color: r['status'] == 200 ? AppColors.neutral700 : AppColors.danger),
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifySetupScreen())),
            icon: const Icon(Icons.phone_android),
            label: const Text('افحص الموبايل ده (الصوت · الظهور · التشغيل التلقائي)'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'لو الخمسة ✓ ولسه مبيوصلش والأبلكيشن مقفول: موبايلات شاومي وأوبو وريلمي وهواوي بتقفل الأبلكيشنز في الخلفية — '
            'من إعدادات الموبايل افتح الأبلكيشن وفعّل «التشغيل التلقائي» وشيل «توفير البطارية» عنه.',
            style: AppText.body(11, color: AppColors.neutral600, height: 1.6),
          ),
        ),
      ],
    );
  }
}
