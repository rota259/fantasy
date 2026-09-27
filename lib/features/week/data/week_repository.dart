import 'models/totw_candidates.dart';
import 'models/week_player.dart';
import 'week_window.dart';

/// عقد إحصائيات الجولة وتشكيلتها.
abstract interface class WeekRepository {
  /// نقاط اللاعيبة في ماتشات فترة معيّنة (الأعلى أولًا).
  /// بتتحسب على منطقتي بس، أو كل المناطق لو [allZones] (أبطال الموسم).
  Future<List<WeekPlayer>> pointsBetween(DateTime from, DateTime to, {bool allZones = false});

  /// تشكيلة الجولة المعتمدة لمنطقتي — null لو لسه الأدمن ماعتمدهاش.
  Future<List<WeekPlayer>?> publishedTeam(WeekWindow window);

  /// آخر جولة الإدارة اعتمدت تشكيلتها لمنطقتي (بتفضل ظاهرة لحد ما اللي بعدها تتعتمد) — null لو مفيش.
  Future<WeekWindow?> latestPublishedRound();

  /// (أدمن) اقتراحات كل المناطق اللي فيها ماتشات في الجولة.
  Future<List<TotwCandidates>> candidates(WeekWindow window);

  /// (أدمن) اعتماد ونشر تشكيلة منطقة (٥ لاعيبة).
  Future<void> publish(WeekWindow window, int zoneId, List<String> playerIds);
}
