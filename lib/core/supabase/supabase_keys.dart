/// مفاتيح Supabase — املأها من:
/// Supabase Dashboard → Project Settings → API
/// - url     = "Project URL"
/// - anonKey = "anon public" key  (مفتاح عام آمن — مش service_role السرّي)
///
/// أول ما تتملأ القيمتين، التطبيق كله بيشتغل live تلقائيًا.
abstract final class SupabaseKeys {
  SupabaseKeys._();

  static const String url = 'https://jhofyglkpwguzodbeyia.supabase.co';
  static const String anonKey = 'sb_publishable_9yzAiTe64aSFpj8_iztWjg_1_M2RJCX';
}
