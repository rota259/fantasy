import 'models/week_player.dart';

/// عقد إحصائيات الجولة.
abstract interface class WeekRepository {
  /// نقاط اللاعيبة في ماتشات فترة معيّنة (الأعلى أولًا) — للجولة بالوقت وأعلى ٥ في اليوم.
  Future<List<WeekPlayer>> pointsBetween(DateTime from, DateTime to);
}
