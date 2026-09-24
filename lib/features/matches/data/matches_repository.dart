import 'models/game_match.dart';

/// عقد بيانات الماتشات/الجولات.
abstract interface class MatchesRepository {
  /// كل الماتشات مرتّبة بالتاريخ.
  Future<List<GameMatch>> fetchAll();

  /// الماتشات القادمة (upcoming) بس.
  Future<List<GameMatch>> fetchUpcoming();

  /// (مدير) إنشاء ماتش جديد.
  Future<void> addMatch({
    required List<String> teams,
    required DateTime dateTime,
    required int week,
  });

  /// (مدير) حذف ماتش — بيرجّع عدد الصفوف المحذوفة (0 = مامعاكش صلاحية).
  Future<int> deleteMatch(String id);

  /// الماتشات اللي خلصت (الأحدث الأول).
  Future<List<GameMatch>> fetchFinished();

  /// (مدير) إنهاء الماتش بنتيجته.
  Future<void> finishMatch(String id, int scoreA, int scoreB);

  /// (مدير) تعديل بيانات ماتش.
  Future<void> updateMatch(String id, {required List<String> teams, required DateTime dateTime, required int week});
}
