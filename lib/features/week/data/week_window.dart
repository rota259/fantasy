import 'package:equatable/equatable.dart';

import '../../../core/app_mode.dart';

/// الجولة: من السبت ٤ العصر لحد السبت اللي بعده ٨ الصبح.
///   • تشكيلات الجولة بتتقفل **السبت ٣ العصر** قبل ما تبدأ (المديرين بيكونوا نزّلوا ماتشاتهم).
///   • السبت من ٨ الصبح لـ ٤ العصر فاصل بين الجولتين — مفيش ماتشات.
///   • أي ماتش بيتحسب في الجولة اللي ميعاده جواها: start <= date_time <= cutoff.
/// (نفس fn_week_cutoff / fn_round_start / fn_round_deadline في السيرفر — بتوقيت الموبايل = القاهرة)
class WeekWindow extends Equatable {
  const WeekWindow(this.cutoff);

  static const startHour = 16; // ٤ العصر
  static const deadlineHour = 15; // ٣ العصر — قبل البداية بساعة
  static const endHour = 8; // ٨ الصبح

  /// نهاية الجولة (السبت ٨ الصبح).
  final DateTime cutoff;

  /// وضع التجربة: جولة واحدة لكل الماتشات (نفس fn_week_cutoff في السيرفر).
  static WeekWindow get testRound => WeekWindow(DateTime(2099, 12, 31, endHour));

  /// بداية الجولة (السبت اللي قبلها ٤ العصر) — في التجربة: من الأول خالص.
  DateTime get start => kTestMode ? DateTime(2000) : DateTime(cutoff.year, cutoff.month, cutoff.day - 7, startHour);

  /// آخر ميعاد للتشكيلة (السبت ٣ العصر يوم البداية).
  /// (وضع التجربة: نهاية الجولة — التشكيلة مفتوحة طولها)
  DateTime get deadline => kTestMode ? cutoff : DateTime(cutoff.year, cutoff.month, cutoff.day - 7, deadlineHour);

  /// الجولة اللي فيها وقت معيّن (الافتراضي: دلوقتي = الجولة الشغّالة، أو الجاية لو إحنا في فاصل السبت).
  factory WeekWindow.current([DateTime? now]) {
    if (kTestMode) return testRound;
    final n = now ?? DateTime.now();
    final daysToSaturday = (DateTime.saturday - n.weekday) % 7; // السبت = 0
    final c = DateTime(n.year, n.month, n.day + daysToSaturday, endHour);
    return WeekWindow(n.isAfter(c) ? DateTime(c.year, c.month, c.day + 7, endHour) : c);
  }

  /// الجولة اللي بتتلعب دلوقتي — وفي فاصل السبت (٨ الصبح لـ ٤ العصر) اللي لسه خالصة.
  factory WeekWindow.live([DateTime? now]) {
    final n = now ?? DateTime.now();
    final cur = WeekWindow.current(n);
    return n.isBefore(cur.start) ? cur.previous : cur;
  }

  /// الجولة اللي التشكيلات مفتوحة ليها: أقرب جولة ديدلاينها لسه مجاش.
  factory WeekWindow.open([DateTime? now]) {
    final n = now ?? DateTime.now();
    final cur = WeekWindow.current(n);
    return n.isBefore(cur.deadline) ? cur : cur.next;
  }

  /// الجولة خلصت — الترتيب نهائي.
  bool isFinal([DateTime? now]) => (now ?? DateTime.now()).isAfter(cutoff);

  /// التشكيلات اتقفلت (عدّى السبت ٣ العصر).
  bool isLocked([DateTime? now]) => !(now ?? DateTime.now()).isBefore(deadline);

  /// الجولة بدأت (السبت ٤ العصر).
  bool hasStarted([DateTime? now]) => (now ?? DateTime.now()).isAfter(start);

  bool contains(DateTime t) => !t.isBefore(start) && !t.isAfter(cutoff);

  /// السبت من ٨ الصبح لـ ٤ العصر (بين جولتين) — مفيش ماتشات.
  static bool inGap(DateTime t) =>
      !kTestMode &&
      t.weekday == DateTime.saturday &&
      t.isAfter(DateTime(t.year, t.month, t.day, endHour)) &&
      t.isBefore(DateTime(t.year, t.month, t.day, startHour));

  WeekWindow get previous => WeekWindow(DateTime(cutoff.year, cutoff.month, cutoff.day - 7, endHour));
  WeekWindow get next => WeekWindow(DateTime(cutoff.year, cutoff.month, cutoff.day + 7, endHour));

  /// "من السبت 19/9 لحد السبت 26/9"
  String get label =>
      kTestMode ? 'جولة التجربة' : 'من السبت ${start.day}/${start.month} لحد السبت ${cutoff.day}/${cutoff.month}';

  @override
  List<Object?> get props => [cutoff];
}

/// النهارده من 12 بالليل لـ 12 بالليل (لأعلى ٥ في اليوم).
({DateTime from, DateTime to}) todayRange([DateTime? now]) {
  final n = now ?? DateTime.now();
  return (from: DateTime(n.year, n.month, n.day), to: DateTime(n.year, n.month, n.day + 1));
}
