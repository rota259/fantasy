import 'models/week_player.dart';

/// عقد إحصائيات الجولة.
abstract interface class WeekRepository {
  /// نقاط اللاعيبة في ماتشات فترة معيّنة (الأعلى أولًا) — للجولة بالوقت وأعلى ٥ في اليوم.
  /// بتتحسب على منطقتي (+ الماتشات العامة)، أو كل المناطق لو [allZones] (أبطال الموسم).
  Future<List<WeekPlayer>> pointsBetween(DateTime from, DateTime to, {bool allZones = false});
}
