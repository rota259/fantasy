import 'models/lineup.dart';

/// عقد تشكيلات الماتش.
abstract interface class LineupRepository {
  /// تشكيلة ماتش (اللاعيبة اللي المدير حطّهم أساسي/احتياطي).
  Future<List<Lineup>> fetchForMatch(String matchId);

  /// تحديد حالة لاعب (starting | bench).
  Future<void> setStatus(String matchId, String playerId, String status);

  /// إخراج لاعب من التشكيلة تمامًا.
  Future<void> remove(String matchId, String playerId);
}
