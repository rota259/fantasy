import 'supabase_keys.dart';

/// مفاتيح Supabase. الأولوية للـ --dart-define، وإلا بتتقري من [SupabaseKeys].
/// `--dart-define=APP_ENV=staging` → مشروع التجربة · من غيره → المشروع الأصلي.
abstract final class SupabaseConfig {
  SupabaseConfig._();

  static const bool isStaging = String.fromEnvironment('APP_ENV') == 'staging';

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: isStaging ? SupabaseKeys.stagingUrl : SupabaseKeys.url,
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: isStaging ? SupabaseKeys.stagingAnonKey : SupabaseKeys.anonKey,
  );

  /// اتأكد إن المفاتيح متظبّطة قبل التشغيل.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
