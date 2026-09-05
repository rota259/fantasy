import 'models/pick.dart';

/// عقد اختيارات التشكيلة لكل ماتش.
abstract interface class PicksRepository {
  /// اختيارات مستخدم لماتش.
  Future<List<Pick>> fetchForUserMatch(String userId, String matchId);

  /// حفظ التشكيلة (بيستبدل القديمة).
  Future<void> savePicks(String userId, String matchId, List<Pick> picks);
}
