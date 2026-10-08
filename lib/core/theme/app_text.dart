import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// خطوط "الخماسي" — كلها Archivo. الوزن 800 للعناوين/الأرقام و600 للتسميات.
/// letter-spacing بيتحسب بالنسبة للحجم (em × size).
/// المقاسات الصغيرة (أقل من ١٣) بتكبر درجة لوحدها — عشان الكلام يتقري براحة والشاشة متبقاش مزحومة.
abstract final class AppText {
  AppText._();

  static double _size(double s) => s < 13 ? s + 1 : s;

  /// عنوان/رقم (heading). الافتراضي وزن 800.
  static TextStyle h(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w800,
    double spacingEm = 0,
    double height = 1.1,
  }) {
    return GoogleFonts.archivo(
      fontSize: _size(size),
      fontWeight: weight,
      color: color ?? AppColors.ink,
      letterSpacing: _size(size) * spacingEm,
      height: height,
    );
  }

  /// كيكر: تسمية صغيرة بأحرف متباعدة (uppercase-ish).
  static TextStyle kicker({Color? color, double size = 9}) {
    return GoogleFonts.archivo(
      fontSize: _size(size),
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.neutral600,
      letterSpacing: _size(size) * 0.08,
    );
  }

  /// نص عادي (body).
  static TextStyle body(double size, {Color? color, FontWeight weight = FontWeight.w400, double height = 1.45}) {
    return GoogleFonts.archivo(
      fontSize: _size(size),
      fontWeight: weight,
      color: color ?? AppColors.ink,
      height: height,
    );
  }
}
