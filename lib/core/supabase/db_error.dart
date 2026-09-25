import 'package:supabase_flutter/supabase_flutter.dart';

/// رسالة خطأ مفهومة من السيرفر.
/// دوال الداتابيز بترمي رسايل عربي جاهزة (raise exception) — بنعرضها زي ما هي.
String dbMessage(Object e, {String fallback = 'حصل خطأ، جرّب تاني'}) {
  if (e is PostgrestException) {
    final m = e.message.trim();
    if (m.isEmpty) return fallback;
    if (e.code == '42501' || m.contains('row-level security')) return 'مش مسموحلك تعمل ده';
    if (e.code == '23505') return 'موجود بالفعل';
    return m;
  }
  if (e is StorageException) return 'الرفع فشل: ${e.message}';
  if (e is AuthException) return e.message;
  return fallback;
}
