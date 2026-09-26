import 'chip_type.dart';
import 'models/chip_status.dart';

/// عقد الكروت الخاصة (على الجولة).
abstract interface class ChipsRepository {
  /// حالة الكروت الأربعة لجولة (بنهايتها).
  Future<List<ChipStatus>> status(DateTime roundEnd);

  /// تفعيل كارت على جولة (مبيتلغيش) — بيرمي رسالة السيرفر لو ممنوع.
  Future<void> activate(DateTime roundEnd, ChipType type);

  /// الكروت اللي اليوزر فعّلها: نهاية الجولة → الكارت.
  Future<Map<DateTime, ChipType>> usedByRound(String userId);
}
