import 'package:flutter/material.dart';

/// الكروت الخاصة. الحدود بتتحدد في السيرفر (activate_chip / chip_status):
///   كابتن ×٣ + الاحتياطي يتحسب + الوايلد كارد → مرتين في كل نص سنة (يناير–يونيو · يوليو–ديسمبر).
///   الدبل ×٢ → مرتين في السنة كلها.
/// كارت واحد في الجولة (على تشكيلة الجولة كلها) ومبيتلغيش.
enum ChipType {
  triple('triple', 'كابتن ×٣', 'نقط الكابتن تتضرب في ٣ بدل ٢ (ولو ملعبش، النائب ياخدها)', Icons.looks_3_outlined),
  benchBoost('bench_boost', 'الاحتياطي يتحسب', 'نقط الاحتياطي الاتنين تتحسب مع الأساسيين', Icons.event_seat_outlined),
  wildcard(
    'wildcard',
    'الوايلد كارد',
    'كل تغييراتك في الجولة دي ببلاش ومن غير ما تاكل من المجاني المتجمّع',
    Icons.all_inclusive,
  ),
  doubleUp('double', 'الدبل ×٢', 'كل نقط تشكيلتك في الجولة دي تتضرب في ٢ (مرتين بس في السنة)', Icons.bolt_outlined);

  const ChipType(this.key, this.label, this.description, this.icon);

  final String key; // الاسم في الداتابيز
  final String label;
  final String description;
  final IconData icon;

  static ChipType? fromKey(String? key) {
    for (final c in values) {
      if (c.key == key) return c;
    }
    return null;
  }
}
