import 'chip_type.dart';
import 'models/chip_status.dart';

/// عقد الكروت الخاصة.
abstract interface class ChipsRepository {
  /// حالة الكروت الأربعة لماتش.
  Future<List<ChipStatus>> status(String matchId);

  /// تفعيل كارت (مبيتلغيش) — بيرمي رسالة السيرفر لو ممنوع.
  Future<void> activate(String matchId, ChipType type);

  /// الكروت اللي اليوزر فعّلها: matchId → الكارت.
  Future<Map<String, ChipType>> usedByMatch(String userId);
}
