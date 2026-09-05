import 'package:flutter/material.dart';

/// توكنز ألوان "الخماسي" — أخضر النجيلة على حبر/ورق.
/// مطابقة للـ design handoff. مفيش لون hard-coded في الشاشات.
abstract final class AppColors {
  AppColors._();

  // ===== الأخضر (الهوية) + السلّم =====
  static const Color accent = Color(0xFF12924A);
  static const Color accent100 = Color(0xFFEAFAF0);
  static const Color accent200 = Color(0xFFC9F0D8);
  static const Color accent300 = Color(0xFF97E2B6);
  static const Color accent400 = Color(0xFF4FCA85); // فاتح — للنقاط على خلفية غامقة
  static const Color accent500 = Color(0xFF1FAE5F);
  static const Color accent600 = Color(0xFF0F8A48);
  static const Color accent700 = Color(0xFF0A6E39); // نص أخضر على فاتح
  static const Color accent800 = Color(0xFF0A542D);
  static const Color accent900 = Color(0xFF0C3D23);

  // ===== أسطح غامقة =====
  static const Color black = Color(0xFF000000);
  static const Color night = Color(0xFF0A0A0A); // أرضية الملعب
  static const Color night2 = Color(0xFF0C0C0C); // البث الحي
  static const Color nightStripe = Color(0xFF0E0E0E); // خطوط الأرضية

  // ===== ورق/حبر =====
  static const Color bg = Color(0xFFF3F2F2); // الأرضية العامة
  static const Color surface = Color(0xFFEAE9E9);
  static const Color ink = Color(0xFF201E1D); // النص الأساسي
  static const Color white = Color(0xFFFFFFFF);

  // ===== سلّم رمادي =====
  static const Color neutral100 = Color(0xFFF0EFEF);
  static const Color neutral200 = Color(0xFFE2E0E0);
  static const Color neutral300 = Color(0xFFD3D1D1); // حدود/مسارات
  static const Color neutral400 = Color(0xFFB8B5B5);
  static const Color neutral500 = Color(0xFF8F8B8B); // رمادي متوسط
  static const Color neutral600 = Color(0xFF6B6867);
  static const Color neutral700 = Color(0xFF4A4746); // نص خافت
  static const Color neutral800 = Color(0xFF2B2928); // شرائح غامقة

  // فاصل: مزيج الحبر 40%
  static const Color divider = Color(0x66201E1D);

  // خطأ/تحذير
  static const Color danger = Color(0xFFDC2626);
}
