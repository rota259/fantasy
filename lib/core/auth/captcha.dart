import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_navigator.dart';
import '../logging/app_log.dart';
import 'captcha_sheet.dart';

/// CAPTCHA (Cloudflare Turnstile) قبل أي عملية دخول — ضد الحسابات الوهمية وتخمين كلمات السر بالبوتات.
///
/// التشغيل:
///   ١) Cloudflare ← Turnstile ← Add widget: الدومين = [domain] · النوع Managed → بياخد Site key و Secret key.
///   ٢) Supabase ← Authentication ← Attack Protection ← CAPTCHA ← Turnstile ← الـ Secret key (عندك انت بس).
///   ٣) البناء بـ  `--dart-define=TURNSTILE_SITE_KEY=...` (الـ site key عام — مش سر).
/// من غير الـ site key الـ CAPTCHA مقفولة هنا (ولو مفعّلة في Supabase الدخول هيترفض — فعّل الاتنين مع بعض).
///
/// العمليات اللي Supabase بيطلب فيها الكود: إنشاء حساب · الدخول (إيميل · رقم · جوجل) · كود تأكيد الإيميل
/// وإعادة إرساله · نسيت كلمة السر. الكود مرة واحدة وصالح ٥ دقايق — فبنجيب واحد جديد قبل كل عملية.
abstract final class Captcha {
  static const siteKey = String.fromEnvironment('TURNSTILE_SITE_KEY');

  /// الدومين المسجّل في Turnstile — الصفحة بتتحمّل كأنها منه (لازم يطابق إعداد الويدجت).
  static const domain = String.fromEnvironment('TURNSTILE_DOMAIN', defaultValue: 'rota259.github.io');

  static bool get enabled => RegExp(r'^[A-Za-z0-9_-]{10,100}$').hasMatch(siteKey);

  /// كود جديد (null لو الـ CAPTCHA مقفولة). لو اليوزر قفل الشاشة أو فشل التحقق → AuthException.
  static Future<String?> token() async {
    if (!enabled) return null;
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) throw const AuthException('جرّب تاني بعد ثانية');
    final t = await showCaptchaSheet(ctx, siteKey: siteKey, domain: domain);
    if (t == null || t.isEmpty) {
      AppLog.warn('auth.captcha.failed');
      throw const AuthException('التحقق إنك مش روبوت مكملش — جرّب تاني');
    }
    return t;
  }
}
