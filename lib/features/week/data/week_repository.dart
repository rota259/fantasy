import 'models/week_player.dart';

/// عقد إحصائيات الجولة.
abstract interface class WeekRepository {
  /// أعلى جولة فيها ماتشات (الافتراضية).
  Future<int> latestWeek();

  /// نقاط اللاعيبة في جولة (الأعلى أولًا).
  Future<List<WeekPlayer>> topPlayers(int week);

  /// نقاط اللاعيبة في ماتشات فترة معيّنة (الأعلى أولًا) — للجولة بالوقت وأعلى ٥ في اليوم.
  Future<List<WeekPlayer>> pointsBetween(DateTime from, DateTime to);
}
