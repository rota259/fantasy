import 'package:flutter/material.dart';

import 'app_palette.dart';

/// توكنز ألوان "الخماسي" — بتتقري من الوضع الحالي (فاتح هادي / داكن) في [AppPalette].
/// مفيش لون hard-coded في الشاشات. تغيير الوضع بيبني الشاشات من جديد (AppThemeScope).
abstract final class AppColors {
  AppColors._();

  static AppPalette _p = AppPalette.light;

  static AppPalette get palette => _p;
  static bool get isDark => _p.brightness == Brightness.dark;

  /// بيتنادى من AppThemeScope قبل بناء الشاشات.
  static void use(AppPalette p) => _p = p;

  // ===== الأخضر (الهوية) + السلّم =====
  static Color get accent => _p.accent;
  static Color get accent100 => _p.accent100;
  static Color get accent200 => _p.accent200;
  static Color get accent300 => _p.accent300;
  static Color get accent400 => _p.accent400; // فاتح — للنقاط على خلفية غامقة
  static Color get accent500 => _p.accent500;
  static Color get accent600 => _p.accent600;
  static Color get accent700 => _p.accent700; // نص أخضر على الأرضية
  static Color get accent800 => _p.accent800;
  static Color get accent900 => _p.accent900;

  // ===== أسطح غامقة =====
  static Color get black => _p.black;
  static Color get night => _p.night; // أرضية الملعب
  static Color get night2 => _p.night2; // البث الحي
  static Color get nightStripe => _p.nightStripe; // خطوط الأرضية

  // ===== ورق/حبر =====
  static Color get bg => _p.bg; // الأرضية العامة
  static Color get surface => _p.surface;
  static Color get card => _p.card; // الكروت
  static Color get ink => _p.ink; // النص الأساسي
  static Color get white => _p.white; // الكلام فوق الأسطح الغامقة

  // ===== سلّم رمادي =====
  static Color get neutral100 => _p.neutral100;
  static Color get neutral200 => _p.neutral200;
  static Color get neutral300 => _p.neutral300;
  static Color get neutral400 => _p.neutral400;
  static Color get neutral500 => _p.neutral500;
  static Color get neutral600 => _p.neutral600;
  static Color get neutral700 => _p.neutral700; // نص خافت
  static Color get neutral800 => _p.neutral800;

  static Color get divider => _p.divider;
  static Color get line => _p.line; // حدود الكروت والحقول
  static Color get shadow => _p.shadow;

  static Color get danger => _p.danger;

  // أزرق: تشكيلة الجولة + علامة التوثيق
  static Color get info => _p.info;
  static Color get navy => _p.navy;
  static Color get navyStripe => _p.navyStripe;
  static Color get navyLine => _p.navyLine;

  // مستويات الشارات
  static Color get bronze => _p.bronze;
  static Color get silver => _p.silver;
  static Color get gold => _p.gold;
}
