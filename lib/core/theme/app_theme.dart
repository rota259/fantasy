import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// ثيم "الخماسي" للوضعين: زوايا ناعمة، حركة هادية بين الشاشات، وشيتات ودايالوجات مدوّرة.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData of(AppPalette p) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: p.brightness,
        primary: p.accent,
        surface: p.bg,
        error: p.danger,
      ),
      splashFactory: InkSparkle.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: p.divider,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SoftPageTransition(),
          TargetPlatform.iOS: _SoftPageTransition(),
          TargetPlatform.windows: _SoftPageTransition(),
          TargetPlatform.macOS: _SoftPageTransition(),
          TargetPlatform.linux: _SoftPageTransition(),
        },
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.neutral400,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.black,
        contentTextStyle: GoogleFonts.archivo(color: p.white, fontWeight: FontWeight.w600, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 1.6),
        ),
        hintStyle: TextStyle(color: p.neutral500),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.accent)),
    );

    return base.copyWith(
      textTheme: GoogleFonts.archivoTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink),
    );
  }
}

/// انتقال ناعم بين الشاشات: ظهور تدريجي + تكبير خفيف (مش سحب جانبي حاد).
class _SoftPageTransition extends PageTransitionsBuilder {
  const _SoftPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(curved), child: child),
    );
  }
}
