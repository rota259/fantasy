import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_service.dart';

var _channelSeq = 0;

/// بتسمع لأي تغيير (إضافة/تعديل/حذف) في جدول وتنادي [onChange] — Realtime.
///
/// بتسمع للتغييرات بس (postgres_changes) من غير ما تنزّل الجدول: الشاشة بتحمّل الداتا بنفسها.
/// التغييرات اللي بتيجي ورا بعض (زي حفظ تشكيلة = ٧ صفوف) بتتجمّع في نداء واحد بعد [debounce].
/// [eqColumn]/[eqValue]: فلترة اختيارية في السيرفر (مثلًا تشكيلة ماتش واحد بس).
StreamSubscription<void>? liveTable(
  String table,
  void Function() onChange, {
  String? eqColumn,
  Object? eqValue,
  Duration debounce = const Duration(milliseconds: 600),
}) {
  if (!SupabaseConfig.isConfigured) return null;
  final client = SupabaseService.client;
  final events = StreamController<void>();
  final channel = client
      .channel('live:$table:${_channelSeq++}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: (eqColumn != null && eqValue != null)
            ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: eqColumn, value: eqValue)
            : null,
        callback: (_) {
          if (!events.isClosed) events.add(null);
        },
      )
      .subscribe(); // انقطاع النت: الـ SDK بيعيد الاتصال لوحده

  Timer? timer;
  events.onCancel = () {
    timer?.cancel();
    client.removeChannel(channel);
  };
  return events.stream.listen((_) {
    timer?.cancel();
    timer = Timer(debounce, onChange);
  });
}
