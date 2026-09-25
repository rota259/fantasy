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

/// حدود الديزاين: صفر انحناء + خطوط 2px صلبة.
abstract final class AppBorders {
  AppBorders._();

  /// الديزاين hard-edge — مفيش أي انحناء.
  static const BorderRadius none = BorderRadius.zero;

  /// حد أسود صلب 2px (العنصر البنائي الأساسي).
  static Border get solid => Border.all(color: AppColors.black, width: 2);

  /// حد فاصل خفيف 2px.
  static Border get divider => Border.all(color: AppColors.divider, width: 2);

  /// حد أبيض شفّاف (على الأسطح الغامقة).
  static Border white(double opacity) => Border.all(color: AppColors.white.withValues(alpha: opacity), width: 2);
}
