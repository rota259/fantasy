import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// خطوط "الخماسي" — كلها Archivo. الوزن 800 للعناوين/الأرقام و600 للتسميات.
/// letter-spacing بيتحسب بالنسبة للحجم (em × size).
abstract final class AppText {
  AppText._();

  /// عنوان/رقم (heading). الافتراضي وزن 800.
  static TextStyle h(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w800,
    double spacingEm = 0,
    double height = 1.1,
  }) {
    return GoogleFonts.archivo(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: size * spacingEm,
      height: height,
    );
  }

  /// كيكر: تسمية صغيرة بأحرف متباعدة (uppercase-ish).
  static TextStyle kicker({
    Color color = AppColors.neutral600,
    double size = 9,
  }) {
    return GoogleFonts.archivo(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: size * 0.14,
    );
  }

  /// نص عادي (body).
  static TextStyle body(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.45,
  }) {
    return GoogleFonts.archivo(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}
