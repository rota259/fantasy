import 'package:fantasy_5omasi/core/app_mode.dart';
import 'package:fantasy_5omasi/features/week/data/week_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => kTestMode = false); // القوانين الحقيقية
  // 2026-09-26 = سبت ، 2026-10-03 = السبت اللي بعده
  test('يوم الأربع: الجولة الشغّالة بدأت السبت ٤ العصر وبتخلص السبت الجاي ٨ الصبح', () {
    final w = WeekWindow.current(DateTime(2026, 9, 23, 20));
    expect(w.cutoff, DateTime(2026, 9, 26, 8));
    expect(w.start, DateTime(2026, 9, 19, 16));
    expect(w.isFinal(DateTime(2026, 9, 23, 20)), isFalse);
  });

  test('السبت ٨ الصبح بالظبط لسه في الجولة، وبعدها الجولة الجاية', () {
    expect(WeekWindow.current(DateTime(2026, 9, 26, 8)).cutoff, DateTime(2026, 9, 26, 8));
    expect(WeekWindow.current(DateTime(2026, 9, 26, 8, 1)).cutoff, DateTime(2026, 10, 3, 8)); // آخر الشهر صح
  });

  test('ماتش في الجولة من البداية لحد النهاية', () {
    final w = WeekWindow(DateTime(2026, 9, 26, 8));
    expect(w.contains(DateTime(2026, 9, 19, 15, 59)), isFalse); // فاصل السبت
    expect(w.contains(DateTime(2026, 9, 19, 16)), isTrue);
    expect(w.contains(DateTime(2026, 9, 26, 8)), isTrue); // آخر ماتشات ليلة الجمعة
    expect(w.contains(DateTime(2026, 9, 26, 8, 1)), isFalse);
  });

  test('فاصل السبت من ٨ الصبح لـ ٤ العصر', () {
    expect(WeekWindow.inGap(DateTime(2026, 9, 26, 10)), isTrue);
    expect(WeekWindow.inGap(DateTime(2026, 9, 26, 8)), isFalse);
    expect(WeekWindow.inGap(DateTime(2026, 9, 26, 16)), isFalse);
    expect(WeekWindow.inGap(DateTime(2026, 9, 25, 10)), isFalse); // الجمعة
  });

  test('الجولة المفتوحة للتشكيلة = الجولة الحالية (مفيش ديدلاين واحد — القفل لكل لاعب)', () {
    // الأربع: الجولة الشغّالة نفسها مفتوحة
    expect(WeekWindow.open(DateTime(2026, 9, 23, 20)).cutoff, DateTime(2026, 9, 26, 8));
    // فاصل السبت (بعد ٨ الصبح): الجولة الجاية
    final noon = DateTime(2026, 9, 26, 15);
    expect(WeekWindow.open(noon).cutoff, DateTime(2026, 10, 3, 8));
    expect(WeekWindow(DateTime(2026, 10, 3, 8)).hasStarted(noon), isFalse);
  });

  test('اللي قبلها واللي بعدها + العنوان', () {
    final w = WeekWindow(DateTime(2026, 9, 26, 8));
    expect(w.previous.cutoff, DateTime(2026, 9, 19, 8));
    expect(w.next.cutoff, DateTime(2026, 10, 3, 8));
    expect(w.label, 'من السبت 19/9 لحد السبت 26/9');
    expect(w.isFinal(DateTime(2026, 9, 26, 8, 1)), isTrue);
  });

  test('الجولة اللي بتتلعب: في فاصل السبت هي اللي لسه خالصة', () {
    expect(WeekWindow.live(DateTime(2026, 9, 23, 20)).cutoff, DateTime(2026, 9, 26, 8));
    expect(WeekWindow.live(DateTime(2026, 9, 26, 10)).cutoff, DateTime(2026, 9, 26, 8)); // الفاصل
    expect(WeekWindow.live(DateTime(2026, 9, 26, 16)).cutoff, DateTime(2026, 10, 3, 8)); // الجديدة بدأت
  });

  test('النهارده من نص الليل لنص الليل', () {
    final r = todayRange(DateTime(2026, 9, 23, 15));
    expect(r.from, DateTime(2026, 9, 23));
    expect(r.to, DateTime(2026, 9, 24));
  });
}
