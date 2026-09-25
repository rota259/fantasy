import 'supabase_keys.dart';

/// مفاتيح Supabase. الأولوية للـ --dart-define، وإلا بتتقري من [SupabaseKeys].
/// أول ما القيمتين يتملّوا (في أي مصدر) التطبيق كله بيشتغل live.
abstract final class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: SupabaseKeys.url);
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: SupabaseKeys.anonKey);

  /// اتأكد إن المفاتيح متظبّطة قبل التشغيل.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
