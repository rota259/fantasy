import 'models/pick.dart';

/// عقد اختيارات التشكيلة لكل ماتش.
abstract interface class PicksRepository {
  /// اختيارات مستخدم لماتش.
  Future<List<Pick>> fetchForUserMatch(String userId, String matchId);

  /// كل تشكيلات اليوزر في كل الماتشات (matchId → اختياراته).
  Future<Map<String, List<Pick>>> fetchAllForUser(String userId);

  /// حفظ التشكيلة (بيستبدل القديمة).
  Future<void> savePicks(String userId, String matchId, List<Pick> picks);
}
