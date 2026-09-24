import 'package:equatable/equatable.dart';

/// دورة الجولة:
///   • من السبت 12 بالليل لحد الجمعة 4 الفجر → **مباشر** (نجوم الجولة وتشكيلة الأسبوع بيتغيّروا مع كل نقطة).
///   • من الجمعة 4 الفجر لحد 12 بالليل → **النهائي** (بيفضل ظاهر ومتقفل).
///   • السبت → جولة جديدة.
/// الحسبة: الجولة = (قفلة الجمعة اللي فاتت 4 الفجر , قفلة الجمعة دي 4 الفجر]،
/// وأي ماتش بيتحسب في الجولة اللي ميعاده جواها.
class WeekWindow extends Equatable {
  const WeekWindow(this.cutoff);

  static const cutoffHour = 4; // 4 الفجر

  /// نهاية الجولة (الجمعة 4 الفجر — بتوقيت الموبايل).
  final DateTime cutoff;

  /// بداية الجولة (الجمعة اللي قبلها 4 الفجر).
  DateTime get start => DateTime(cutoff.year, cutoff.month, cutoff.day - 7, cutoffHour);

  /// الجولة اللي ظاهرة دلوقتي.
  /// الجمعة قبل 4 → الجولة دي لسه مباشر. الجمعة بعد 4 → نفس الجولة بس نهائي. السبت → الجولة الجاية.
  factory WeekWindow.current([DateTime? now]) {
    final n = now ?? DateTime.now();
    final daysToFriday = (DateTime.friday - n.weekday) % 7; // الجمعة = 0
    return WeekWindow(DateTime(n.year, n.month, n.day + daysToFriday, cutoffHour));
  }

  /// الجولة خلصت (من الجمعة 4 الفجر) — الترتيب نهائي.
  bool isFinal([DateTime? now]) => (now ?? DateTime.now()).isAfter(cutoff);

  WeekWindow get previous => WeekWindow(DateTime(cutoff.year, cutoff.month, cutoff.day - 7, cutoffHour));
  WeekWindow get next => WeekWindow(DateTime(cutoff.year, cutoff.month, cutoff.day + 7, cutoffHour));

  /// السبت اللي الجولة بتبدأ فيه (للعرض).
  DateTime get saturday => DateTime(start.year, start.month, start.day + 1);

  /// "من السبت 20/9 لحد الجمعة 26/9"
  String get label => 'من السبت ${saturday.day}/${saturday.month} لحد الجمعة ${cutoff.day}/${cutoff.month}';

  @override
  List<Object?> get props => [cutoff];
}

/// النهارده من 12 بالليل لـ 12 بالليل (لأعلى ٥ في اليوم).
({DateTime from, DateTime to}) todayRange([DateTime? now]) {
  final n = now ?? DateTime.now();
  return (from: DateTime(n.year, n.month, n.day), to: DateTime(n.year, n.month, n.day + 1));
}
