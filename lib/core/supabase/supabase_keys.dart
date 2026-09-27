/// مفاتيح Supabase — املأها من:
/// Supabase Dashboard → Project Settings → API
/// - url     = "Project URL"
/// - anonKey = "anon public" key  (مفتاح عام آمن — مش service_role السرّي)
///
/// أول ما تتملأ القيمتين، التطبيق كله بيشتغل live تلقائيًا.
abstract final class SupabaseKeys {
  SupabaseKeys._();

  // المشروع الأصلي (production)
  static const String url = 'https://jhofyglkpwguzodbeyia.supabase.co';
  static const String anonKey = 'sb_publishable_9yzAiTe64aSFpj8_iztWjg_1_M2RJCX';

  // مشروع التجربة (staging) — flutter run --dart-define=APP_ENV=staging
  static const String stagingUrl = 'https://tnziqngtcxrufskdesod.supabase.co';
  static const String stagingAnonKey = 'sb_publishable_8hHaK46RqG0mjT1-YOEOmw_40ZCUTjS';
}
