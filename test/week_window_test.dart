import 'package:fantasy_5omasi/features/week/data/week_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-09-26 = سبت ، 2026-10-03 = السبت اللي بعده
  test('يوم الأربع: الجولة الشغّالة بتخلص السبت الجاي ٤ العصر', () {
    final w = WeekWindow.current(DateTime(2026, 9, 23, 20));
    expect(w.cutoff, DateTime(2026, 9, 26, 16));
    expect(w.start, DateTime(2026, 9, 19, 16));
    expect(w.deadline, DateTime(2026, 9, 19, 12));
    expect(w.isFinal(DateTime(2026, 9, 23, 20)), isFalse);
  });

  test('السبت ٤ العصر بالظبط لسه في الجولة، وبعدها بدقيقة جولة جديدة', () {
    expect(WeekWindow.current(DateTime(2026, 9, 26, 16)).cutoff, DateTime(2026, 9, 26, 16));
    expect(WeekWindow.current(DateTime(2026, 9, 26, 16, 1)).cutoff, DateTime(2026, 10, 3, 16)); // آخر الشهر صح
  });

  test('ماتش في الجولة لو بعد البداية ولحد النهاية', () {
    final w = WeekWindow(DateTime(2026, 9, 26, 16));
    expect(w.contains(DateTime(2026, 9, 19, 16)), isFalse); // بتاع اللي قبلها
    expect(w.contains(DateTime(2026, 9, 19, 16, 1)), isTrue);
    expect(w.contains(DateTime(2026, 9, 26, 16)), isTrue);
  });

  test('الجولة المفتوحة للتشكيلات: قبل السبت ١٢ الجاية، بعده اللي بعدها', () {
    // الأربع: الجولة الجاية (تبدأ السبت ٤) لسه مفتوحة
    expect(WeekWindow.open(DateTime(2026, 9, 23, 20)).cutoff, DateTime(2026, 10, 3, 16));
    // السبت ١١:٥٩ الضهر: لسه مفتوحة
    expect(WeekWindow.open(DateTime(2026, 9, 26, 11, 59)).cutoff, DateTime(2026, 10, 3, 16));
    // السبت ١٢ الضهر: اتقفلت → اللي بعدها
    final noon = DateTime(2026, 9, 26, 12);
    expect(WeekWindow.open(noon).cutoff, DateTime(2026, 10, 10, 16));
    expect(WeekWindow(DateTime(2026, 10, 3, 16)).isLocked(noon), isTrue);
    expect(WeekWindow(DateTime(2026, 10, 3, 16)).hasStarted(noon), isFalse);
  });

  test('اللي قبلها واللي بعدها + العنوان', () {
    final w = WeekWindow(DateTime(2026, 9, 26, 16));
    expect(w.previous.cutoff, DateTime(2026, 9, 19, 16));
    expect(w.next.cutoff, DateTime(2026, 10, 3, 16));
    expect(w.label, 'من السبت 19/9 لحد السبت 26/9');
    expect(w.isFinal(DateTime(2026, 9, 26, 16, 1)), isTrue);
  });

  test('النهارده من نص الليل لنص الليل', () {
    final r = todayRange(DateTime(2026, 9, 23, 15));
    expect(r.from, DateTime(2026, 9, 23));
    expect(r.to, DateTime(2026, 9, 24));
  });
}
