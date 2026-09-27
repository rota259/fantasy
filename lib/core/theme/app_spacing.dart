import 'package:flutter/material.dart';

import 'app_colors.dart';

/// وحدات المسافات — أساس 4px زي الـ handoff.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 24;
  static const double xxxl = 34;

  /// الـ padding الأفقي الافتراضي للشاشات.
  static const double screenH = 16;
}

/// الزوايا: ناعمة ومتسقة في التطبيق كله.
abstract final class AppRadius {
  AppRadius._();

  static const double s = 8; // شارات صغيرة
  static const double m = 14; // كروت وزراير وحقول
  static const double l = 22; // شيتات وكروت كبيرة

  static const BorderRadius sm = BorderRadius.all(Radius.circular(s));
  static const BorderRadius md = BorderRadius.all(Radius.circular(m));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(l));
}

/// الحدود: خطوط رفيعة هادية (بدل الأسود التقيل).
abstract final class AppBorders {
  AppBorders._();

  static const BorderRadius none = BorderRadius.zero;

  /// حد الكروت والحقول.
  static Border get solid => Border.all(color: AppColors.line, width: 1.2);

  /// حد فاصل خفيف.
  static Border get divider => Border.all(color: AppColors.divider, width: 1.2);

  /// حد أبيض شفّاف (على الأسطح الغامقة).
  static Border white(double opacity) => Border.all(color: AppColors.white.withValues(alpha: opacity), width: 1.2);
}
