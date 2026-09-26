import 'models/pick.dart';

/// عقد تشكيلة الجولة (٧ لاعيبة من منطقتك).
abstract interface class PicksRepository {
  /// تشكيلتي في جولة (بنهايتها).
  Future<List<Pick>> fetchRound(String userId, DateTime roundEnd);

  /// كل تشكيلاتي: نهاية الجولة → اختياراتها.
  Future<Map<DateTime, List<Pick>>> fetchAllRounds(String userId);

  /// حفظ تشكيلة الجولة (بيستبدل القديمة) — السيرفر بيتحقق من القواعد والديدلاين.
  Future<void> saveRound(DateTime roundEnd, List<Pick> picks);
}
