import 'package:supabase_flutter/supabase_flutter.dart';

import '../logging/log_http_client.dart';
import 'secure_session_storage.dart';
import 'supabase_config.dart';

/// نقطة وصول واحدة للـ Supabase client في التطبيق كله.
abstract final class SupabaseService {
  SupabaseService._();

  /// بتتنادى مرة واحدة في main() قبل runApp().
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // القيمة نفسها (anon / publishable key) — الاسم الجديد في الإصدار الحديث.
      publishableKey: SupabaseConfig.anonKey,
      // كل طلب بياخد رقم X-Request-ID وبيتسجّل (المسار · الكود · المدة) — core/logging
      httpClient: LogHttpClient(),
      // جلسة الدخول متشفّرة (Android Keystore / iOS Keychain) بدل ملف عادي
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage('sb-${Uri.parse(SupabaseConfig.url).host.split('.').first}-auth-token'),
        pkceAsyncStorage: const SecurePkceStorage(),
      ),
    );
  }

  /// الـ client الجاهز للاستعلامات.
  static SupabaseClient get client => Supabase.instance.client;

  /// اختصار لجدول معيّن.
  static SupabaseQueryBuilder table(String name) => client.from(name);

  /// المستخدم الحالي (لو مسجّل دخول).
  static User? get currentUser => client.auth.currentUser;
}
