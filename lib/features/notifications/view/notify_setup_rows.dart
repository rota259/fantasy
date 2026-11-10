part of 'notify_setup_screen.dart';

extension _NotifySetupRows on _NotifySetupScreenState {
  List<Widget> _rows(DeviceNotifyStatus s) => [
    _row(
      'الإشعارات مسموحة للأبلكيشن',
      s.enabled,
      fix: 'الموبايل مانع إشعارات الخماسي خالص',
      action: ('فعّلها', DeviceNotify.requestPermission),
    ),
    for (final c in s.channels)
      _row(
        'إشعارات «${c.name}»',
        c.ok,
        fix: c.importance == 0
            ? 'النوع ده مقفول — افتحه وفعّله'
            : 'مش بتعمل صوت أو مش بتظهر فوق الشاشة — افتحها وفعّل «الصوت» و«الظهور فوق الشاشة / Pop-up»',
        action: ('افتح الإعداد', () => DeviceNotify.openChannel(c.id)),
      ),
    if (s.strictMaker)
      _row(
        'التشغيل التلقائي (${s.manufacturer})',
        null,
        fix:
            'موبايلات الشركة دي بتمنع الأبلكيشنات الجديدة تستقبل إشعارات وهي مقفولة. فعّل «التشغيل التلقائي / Autostart» '
            'للخماسي، ومن إعدادات الإشعارات فعّل «شاشة القفل» و«الإشعارات العائمة».',
        action: ('افتح التشغيل التلقائي', DeviceNotify.openAutostart),
      ),
    _row(
      'الأبلكيشن مش محكوم بتوفير البطارية',
      !s.batteryOptimized,
      fix: 'توفير البطارية ممكن يأخّر الإشعار أو يمنعه والأبلكيشن مقفول — اختار «بدون قيود / No restrictions»',
      action: ('افتح إعدادات البطارية', DeviceNotify.openBattery),
    ),
  ];

  /// [ok] null = خطوة لازم تعملها بإيدك (الموبايل مبيقولش حالتها).
  Widget _row(String title, bool? ok, {required String fix, (String, Future<void> Function())? action}) {
    final color = ok == true ? AppColors.accent700 : (ok == false ? AppColors.danger : const Color(0xFFE08A00));
    return Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok == true ? Icons.check_circle : (ok == false ? Icons.error_outline : Icons.touch_app_outlined),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppText.h(13))),
            ],
          ),
          if (ok != true) ...[
            const SizedBox(height: 6),
            Text(fix, style: AppText.body(12, color: AppColors.neutral700)),
            if (action != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(onPressed: action.$2, child: Text(action.$1)),
              ),
          ],
        ],
      ),
    );
  }
}
