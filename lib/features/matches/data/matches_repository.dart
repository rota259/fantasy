import 'models/game_match.dart';

/// عقد بيانات الماتشات/الجولات.
abstract interface class MatchesRepository {
  /// كل الماتشات مرتّبة بالتاريخ.
  Future<List<GameMatch>> fetchAll();

  /// (منظّم) ماتشاتي بس، الأحدث الأول.
  Future<List<GameMatch>> fetchOrganizedBy(String userId);

  /// الماتشات القادمة (upcoming) بس — في منطقتي + العامة.
  Future<List<GameMatch>> fetchUpcoming();

  /// (مدير/منظّم) إنشاء ماتش جديد — السيرفر بيسجّل المنظّم لوحده.
  Future<void> addMatch({required List<String> teams, required DateTime dateTime, required int week});

  /// (مدير) حذف ماتش — بيرجّع عدد الصفوف المحذوفة (0 = مامعاكش صلاحية).
  Future<int> deleteMatch(String id);

  /// ماتشات معيّنة بالـ ids.
  Future<List<GameMatch>> fetchByIds(List<String> ids);

  /// آخر الماتشات اللي خلصت (الأحدث الأول) — في منطقتي + العامة.
  Future<List<GameMatch>> fetchFinished();

  /// (مدير) إنهاء الماتش بنتيجته.
  Future<void> finishMatch(String id, int scoreA, int scoreB);

  /// (مدير) تعديل بيانات ماتش.
  Future<void> updateMatch(String id, {required List<String> teams, required DateTime dateTime, required int week});
}
