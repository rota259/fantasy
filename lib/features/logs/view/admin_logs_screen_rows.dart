part of 'admin_logs_screen.dart';

extension _AdminLogsRows on _AdminLogsScreenState {
  Color _color(String level) => switch (level) {
    'error' || 'fatal' => AppColors.danger,
    'warn' => const Color(0xFFE08A00),
    _ => AppColors.neutral600,
  };

  /// سطر واحد: المستوى · الحدث · الوقت — والضغط بيفتح التفاصيل كلها.
  Widget _row(LogRow r) => Pressable(
    onTap: () => _details(r),
    child: Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: AppDecor.tile,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(color: _color(r.level), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.errorType ?? r.event, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(13)),
                Text(
                  [
                    r.event,
                    if (r.route != null) r.route!,
                    if (r.status != null) '${r.status}',
                    if (r.durationMs != null) '${r.durationMs}ms',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${r.at.day}/${r.at.month} ${arabicTime(r.at)}', style: AppText.body(10, color: AppColors.neutral600)),
        ],
      ),
    ),
  );

  /// كل حقول السطر — وزرار «نفس الطلب» بيجيب كل سطور الطلب ده، ونسخ الرقم.
  void _details(LogRow r) {
    final lines = <(String, String?)>[
      ('الوقت', '${r.at.toUtc().toIso8601String()} (UTC)'),
      ('المستوى', r.level),
      ('الخدمة', '${r.service}${r.version == null ? '' : ' · ${r.version}'}'),
      ('الحدث', r.event),
      ('الطلب', r.route == null ? null : '${r.route} → ${r.status ?? '-'} · ${r.durationMs ?? '-'}ms'),
      ('رقم الطلب', r.requestId),
      ('اليوزر', r.userId),
      ('الرسالة', r.message),
      ('الخطأ', r.errorType),
      for (final f in r.fields.entries) (f.key, '${f.value}'),
      ('stack', r.stack),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.8),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(18),
            children: [
              for (final l in lines.where((l) => l.$2 != null && l.$2!.isNotEmpty)) ...[
                Text(l.$1, style: AppText.kicker()),
                SelectableText(l.$2!, textDirection: TextDirection.ltr, style: AppText.body(12)),
                const SizedBox(height: 10),
              ],
              if (r.requestId != null)
                Row(
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(c);
                        _searchFor(r.requestId!);
                      },
                      child: const Text('كل سطور الطلب ده'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Clipboard.setData(ClipboardData(text: r.requestId!)),
                      child: const Text('انسخ الرقم'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// مستوى السجلات عند كل الناس — بيتغيّر من غير نسخة جديدة (بيتطبّق أول ما الأبلكيشن يتفتح).
  Widget _levelCard() => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    padding: const EdgeInsets.all(14),
    decoration: AppDecor.tile,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مستوى السجلات', style: AppText.h(13)),
        Text(
          'العادي info. علّيه لـ debug وقت ما تدوّر على مشكلة بس ورجّعه — debug مبيتبعتش للسيرفر، بيظهر على الجهاز.',
          style: AppText.body(11, color: AppColors.neutral700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final l in const ['debug', 'info', 'warn', 'error'])
              ChoiceChip(label: Text(l), selected: _appLevel == l, onSelected: (_) => _setLevel(l)),
          ],
        ),
      ],
    ),
  );
}
