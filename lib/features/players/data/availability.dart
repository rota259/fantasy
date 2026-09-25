import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// حالة جاهزية اللاعب (المدير بيحدّدها).
abstract final class Availability {
  Availability._();

  static const ready = 'ready';
  static const injured = 'injured';
  static const doubtful = 'doubtful';
  static const suspended = 'suspended';

  static const all = [ready, injured, doubtful, suspended];

  static String label(String a) => switch (a) {
    injured => 'مصاب',
    doubtful => 'مشكوك',
    suspended => 'موقوف',
    _ => 'جاهز',
  };

  /// نسبة الجاهزية (للعرض جنب الحالة).
  static String? percent(String a) => switch (a) {
    ready => '100%',
    doubtful => '50%',
    injured => '0%',
    _ => null,
  };

  /// الحالة + النسبة، مثلاً "جاهز 100%".
  static String statusLine(String a) {
    final p = percent(a);
    return p == null ? label(a) : '${label(a)} $p';
  }

  static IconData icon(String a) => switch (a) {
    injured => Icons.local_hospital,
    doubtful => Icons.help,
    suspended => Icons.block,
    _ => Icons.check_circle,
  };

  static Color color(String a) => switch (a) {
    injured => AppColors.danger,
    doubtful => const Color(0xFFCA8A04), // أصفر غامق
    suspended => AppColors.danger,
    _ => AppColors.accent,
  };

  /// ترشيحات أسباب لكل حالة (المدير يختار أو يكتب).
  static List<String> reasons(String a) => switch (a) {
    injured => const ['إصابة عضلية', 'التواء كاحل', 'إصابة في الركبة', 'إرهاق شديد'],
    doubtful => const ['مشكوك في جاهزيته', 'راجع من إصابة', 'مرتبط بشغل', 'متأخّر على الماتش'],
    suspended => const ['إيقاف كروت', 'إيقاف إداري'],
    _ => const [],
  };
}
