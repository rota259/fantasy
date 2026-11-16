import 'models/lineup.dart';

/// عقد تشكيلات الماتش.
abstract interface class LineupRepository {
  /// تشكيلة ماتش (اللاعيبة اللي المدير حطّهم أساسي/احتياطي).
  Future<List<Lineup>> fetchForMatch(String matchId);

  /// تحديد حالة لاعب (starting | bench).
  Future<void> setStatus(String matchId, String playerId, String status);

  /// إخراج لاعب من التشكيلة تمامًا.
  Future<void> remove(String matchId, String playerId);

  /// (مدير) حفظ التشكيلة كاملة مرة واحدة — بيستبدل القديمة.
  /// entries: playerId → starting|bench (اللي مش موجود = بره).
  Future<void> replaceForMatch(String matchId, Map<String, String> entries, {int? format});

  /// (كابتن) ابعت تشكيلة فريقك للمدير: playerId → starting|bench.
  Future<void> submitTeam(String matchId, Map<String, String> entries);

  /// التشكيلات اللي بعتها الكباتن للماتش (للمدير، وللكابتن تشكيلته).
  Future<List<TeamLineup>> teamLineups(String matchId);

  /// (المدير) طبّق تشكيلة الكابتن على الماتش.
  Future<void> applyTeam(String matchId, String team);

  /// (المدير) فكّر كابتن الفريق يبعت التشكيلة — مرة كل ساعة.
  Future<void> remindTeam(String matchId, String team);
}
