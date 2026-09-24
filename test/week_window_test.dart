import 'package:fantasy_5omasi/features/week/data/week_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-09-25 = جمعة ، 2026-09-26 = سبت
  test('يوم الأربع: الجولة لسه مباشر وبتقفل الجمعة الجاية 4 الفجر', () {
    final w = WeekWindow.current(DateTime(2026, 9, 23, 20));
    expect(w.cutoff, DateTime(2026, 9, 25, 4));
    expect(w.start, DateTime(2026, 9, 18, 4));
    expect(w.isFinal(DateTime(2026, 9, 23, 20)), isFalse);
  });

  test('الجمعة 3 الفجر: لسه مباشر', () {
    final now = DateTime(2026, 9, 25, 3, 59);
    final w = WeekWindow.current(now);
    expect(w.cutoff, DateTime(2026, 9, 25, 4));
    expect(w.isFinal(now), isFalse);
  });

  test('الجمعة 4 وخمسة: نفس الجولة بس نهائي', () {
    final now = DateTime(2026, 9, 25, 4, 5);
    final w = WeekWindow.current(now);
    expect(w.cutoff, DateTime(2026, 9, 25, 4));
    expect(w.isFinal(now), isTrue);
  });

  test('الجمعة 11:59 بالليل: لسه النهائي ظاهر', () {
    final now = DateTime(2026, 9, 25, 23, 59);
    expect(WeekWindow.current(now).cutoff, DateTime(2026, 9, 25, 4));
    expect(WeekWindow.current(now).isFinal(now), isTrue);
  });

  test('السبت 12 بالليل: جولة جديدة مباشر', () {
    final now = DateTime(2026, 9, 26, 0, 0);
    final w = WeekWindow.current(now);
    expect(w.cutoff, DateTime(2026, 10, 2, 4)); // عدّت آخر الشهر صح
    expect(w.isFinal(now), isFalse);
  });

  test('اللي قبلها واللي بعدها + العنوان', () {
    final w = WeekWindow(DateTime(2026, 9, 25, 4));
    expect(w.previous.cutoff, DateTime(2026, 9, 18, 4));
    expect(w.next.cutoff, DateTime(2026, 10, 2, 4));
    expect(w.label, 'من السبت 19/9 لحد الجمعة 25/9');
  });

  test('النهارده من نص الليل لنص الليل', () {
    final r = todayRange(DateTime(2026, 9, 30, 15));
    expect(r.from, DateTime(2026, 9, 30));
    expect(r.to, DateTime(2026, 10, 1));
  });
}
