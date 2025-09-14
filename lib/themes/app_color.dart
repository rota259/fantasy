import 'package:flutter/material.dart';

class AppColors {
  // خلفية عامة للتطبيق
  static const Color backgroundDark = Color.fromRGBO(53, 55, 75, 1); // رمادي غامق
  static const Color backgroundMedium = Color.fromRGBO(52, 73, 85, 1); // رمادي مزرق
  static const Color backgroundSoft = Color.fromRGBO(80, 114, 123, 1); // أزرق رمادي ناعم
  static const Color accentGreen = Color.fromRGBO(120, 160, 131, 1); // أخضر هادي

  // ألوان رئيسية للـ Theme
  static const Color primary = backgroundDark;
  static const Color secondary = backgroundSoft;
  static const Color surface = backgroundMedium;
  static const Color success = accentGreen;

  // ألوان النصوص
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  // ألوان الأزرار
  static const Color buttonBackground = accentGreen;
  static const Color buttonText = Colors.white;
}
