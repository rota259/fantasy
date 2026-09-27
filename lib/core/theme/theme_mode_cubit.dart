import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// وضع الألوان: تلقائي (حسب الموبايل) · فاتح · داكن — بيتحفظ على الجهاز.
class ThemeModeCubit extends Cubit<ThemeMode> {
  ThemeModeCubit() : super(ThemeMode.system) {
    _load();
  }

  static const _key = 'theme_mode';

  Future<void> _load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
      if (mode != null && !isClosed) emit(mode);
    } catch (_) {}
  }

  Future<void> set(ThemeMode mode) async {
    emit(mode);
    try {
      await (await SharedPreferences.getInstance()).setString(_key, mode.name);
    } catch (_) {}
  }

  /// تلقائي → فاتح → داكن → تلقائي.
  void cycle() => set(switch (state) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });

  static String label(ThemeMode m) => switch (m) {
    ThemeMode.system => 'تلقائي (زي الموبايل)',
    ThemeMode.light => 'فاتح',
    ThemeMode.dark => 'داكن',
  };
}
