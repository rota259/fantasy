import 'package:equatable/equatable.dart';

/// الجولة: من السبت ٤ العصر لحد السبت اللي بعده ٤ العصر.
///   • تشكيلات الجولة بتتقفل **السبت ١٢ الضهر** قبل ما تبدأ (المنظّمين بيكونوا نزّلوا ماتشاتهم).
///   • أي ماتش بيتحسب في الجولة اللي ميعاده جواها: start < date_time <= cutoff.
/// (نفس fn_week_cutoff / fn_round_deadline في السيرفر — بتوقيت الموبايل = القاهرة)
class WeekWindow extends Equatable {
  const WeekWindow(this.cutoff);

  static const startHour = 16; // ٤ العصر
  static const deadlineHour = 12; // ١٢ الضهر

  /// نهاية الجولة (السبت ٤ العصر).
  final DateTime cutoff;

  /// بداية الجولة (السبت اللي قبلها ٤ العصر).
  DateTime get start => DateTime(cutoff.year, cutoff.month, cutoff.day - 7, startHour);

  /// آخر ميعاد للتشكيلة (السبت ١٢ الضهر يوم البداية).
  DateTime get deadline => DateTime(cutoff.year, cutoff.month, cutoff.day - 7, deadlineHour);

  /// الجولة اللي فيها وقت معيّن (الافتراضي: دلوقتي = الجولة الشغّالة).
  factory WeekWindow.current([DateTime? now]) {
    final n = now ?? DateTime.now();
    final daysToSaturday = (DateTime.saturday - n.weekday) % 7; // السبت = 0
    final c = DateTime(n.year, n.month, n.day + daysToSaturday, startHour);
    return WeekWindow(n.isAfter(c) ? DateTime(c.year, c.month, c.day + 7, startHour) : c);
  }

  /// الجولة اللي التشكيلات مفتوحة ليها: أقرب جولة ديدلاينها لسه مجاش.
  factory WeekWindow.open([DateTime? now]) {
    final n = now ?? DateTime.now();
    final next = WeekWindow.current(n).next;
    return n.isBefore(next.deadline) ? next : next.next;
  }

  /// الجولة خلصت — الترتيب نهائي.
  bool isFinal([DateTime? now]) => (now ?? DateTime.now()).isAfter(cutoff);

  /// التشكيلات اتقفلت (عدّى السبت ١٢ الضهر).
  bool isLocked([DateTime? now]) => !(now ?? DateTime.now()).isBefore(deadline);

  /// الجولة بدأت (السبت ٤ العصر).
  bool hasStarted([DateTime? now]) => (now ?? DateTime.now()).isAfter(start);

  bool contains(DateTime t) => t.isAfter(start) && !t.isAfter(cutoff);

  WeekWindow get previous => WeekWindow(DateTime(cutoff.year, cutoff.month, cutoff.day - 7, startHour));
  WeekWindow get next => WeekWindow(DateTime(cutoff.year, cutoff.month, cutoff.day + 7, startHour));

  /// "من السبت 19/9 لحد السبت 26/9"
  String get label => 'من السبت ${start.day}/${start.month} لحد السبت ${cutoff.day}/${cutoff.month}';

  @override
  List<Object?> get props => [cutoff];
}

/// النهارده من 12 بالليل لـ 12 بالليل (لأعلى ٥ في اليوم).
({DateTime from, DateTime to}) todayRange([DateTime? now]) {
  final n = now ?? DateTime.now();
  return (from: DateTime(n.year, n.month, n.day), to: DateTime(n.year, n.month, n.day + 1));
}
