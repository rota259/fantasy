import 'models/game_match.dart';
import 'models/late_match_request.dart';

/// عقد بيانات الماتشات/الجولات.
abstract interface class MatchesRepository {
  /// كل الماتشات مرتّبة بالتاريخ.
  Future<List<GameMatch>> fetchAll();

  /// (مدير) ماتشاتي بس، الأحدث الأول.
  Future<List<GameMatch>> fetchOrganizedBy(String userId);

  /// الماتشات القادمة (upcoming) بس — في منطقتي + العامة.
  Future<List<GameMatch>> fetchUpcoming();

  /// (مدير/مدير) إنشاء ماتش جديد — السيرفر بيسجّل المدير لوحده.
  Future<void> addMatch({required List<String> teams, required DateTime dateTime, required int week});

  /// (مدير) حذف ماتش — بيرجّع عدد الصفوف المحذوفة (0 = مامعاكش صلاحية).
  Future<int> deleteMatch(String id);

  /// ماتشات جولة في منطقتي (من بدايتها لنهايتها) — لحالة كل لاعب: لعب ولا لسه.
  Future<List<GameMatch>> fetchInWindow(DateTime start, DateTime end);

  /// ماتشات معيّنة بالـ ids.
  Future<List<GameMatch>> fetchByIds(List<String> ids);

  /// آخر الماتشات اللي خلصت (الأحدث الأول) — في منطقتي + العامة.
  Future<List<GameMatch>> fetchFinished();

  /// (مدير) إنهاء الماتش بنتيجته.
  Future<void> finishMatch(String id, int scoreA, int scoreB);

  /// (مدير) تعديل بيانات ماتش.
  Future<void> updateMatch(String id, {required List<String> teams, required DateTime dateTime, required int week});

  /// (مدير منطقة) الديدلاين عدّى → طلب للأدمن يضيف الماتش.
  Future<void> requestLateMatch({required List<String> teams, required DateTime dateTime, String? note});

  /// (أدمن) طلبات الماتشات المتأخرة المستنية.
  Future<List<LateMatchRequest>> pendingLateMatches();

  /// (أدمن) موافقة (الماتش بيتعمل باسم المدير) أو رفض.
  Future<void> reviewLateMatch(String requestId, bool approve);
}
