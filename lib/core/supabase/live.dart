import 'dart:async';

import 'supabase_config.dart';
import 'supabase_service.dart';

/// بتسمع لأي تغيير (إضافة/تعديل/حذف) في جدول وتنادي [onChange] — Realtime.
/// أول إرسال (الداتا الحالية) بيتجاهل لأن الشاشة بتحمّلها بنفسها.
/// [eqColumn]/[eqValue]: فلترة اختيارية (مثلًا تشكيلة ماتش واحد بس).
/// [primaryKey]: أعمدة المفتاح الأساسي للجدول (الافتراضي id).
StreamSubscription<void>? liveTable(
  String table,
  void Function() onChange, {
  String? eqColumn,
  Object? eqValue,
  List<String> primaryKey = const ['id'],
}) {
  if (!SupabaseConfig.isConfigured) return null;
  final base = SupabaseService.client.from(table).stream(primaryKey: primaryKey);
  final stream = (eqColumn != null && eqValue != null) ? base.eq(eqColumn, eqValue) : base;
  var first = true;
  return stream.listen(
    (_) {
      if (first) {
        first = false;
        return;
      }
      onChange();
    },
    onError: (_) {}, // انقطاع النت: الـ SDK بيعيد الاتصال لوحده
  );
}
