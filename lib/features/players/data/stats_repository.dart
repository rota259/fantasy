import '../../week/data/week_window.dart';
import 'models/player_gw_stat.dart';

/// عقد إحصائيات اللاعيبة بالجولة (نقاط / امتلاك / دخول وخروج / تاريخ).
abstract interface class StatsRepository {
  /// إحصائيات كل اللاعيبة في جولة بالوقت (playerId → stat).
  Future<Map<String, PlayerGwStat>> windowStats(WeekWindow week);

  /// نقاط لاعب في كل جولة لعبها.
  Future<List<({int gw, int points})>> history(String playerId);
}
