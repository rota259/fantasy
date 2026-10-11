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
  if (e is StorageException) {
    final m = e.message.toLowerCase();
    if (m.contains('row-level security') || m.contains('unauthorized') || e.statusCode == '403') {
      return 'مش مسموحلك ترفع الصورة دي (اللاعب لازم يكون في فريق من فرقك)';
    }
    if (m.contains('bucket not found')) return 'مكان الصور مش متجهّز — شغّل ملف الداتابيز تاني';
    if (m.contains('mime') || m.contains('type')) return 'نوع الصورة مش مدعوم — اختار JPG أو PNG';
    if (m.contains('size') || m.contains('too large') || e.statusCode == '413') return 'الصورة كبيرة — اختار صورة أصغر';
    return 'الرفع فشل: ${e.message}';
  }
  if (e is AuthException) return e.message;
  return fallback;
}
