import 'models/pick.dart';
import 'models/round_locks.dart';

/// عقد تشكيلة الجولة (٧ لاعيبة من منطقتك).
abstract interface class PicksRepository {
  /// تشكيلتي في جولة (بنهايتها).
  Future<List<Pick>> fetchRound(String userId, DateTime roundEnd);

  /// كل تشكيلاتي: نهاية الجولة → اختياراتها.
  Future<Map<DateTime, List<Pick>>> fetchAllRounds(String userId);

  /// قفل كل لاعب في الجولة + تشكيلة الجولة اللي فاتت (لعدّ التغييرات) + الوايلد كارد.
  Future<RoundLocks> roundLocks(DateTime roundEnd);

  /// حفظ تشكيلة الجولة (بيستبدل القديمة) — السيرفر بيتحقق من القواعد وقفل كل لاعب.
  Future<void> saveRound(DateTime roundEnd, List<Pick> picks);
}
