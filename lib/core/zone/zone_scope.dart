/// منطقة اليوزر الحالي (بتتحدد بعد الدخول في AppRoot).
/// الـ repositories بتفلتر بيها اللي اليوزر بيشوفه: ماتشات ولاعيبة ونجم وتشكيلة منطقته + العامة.
abstract final class ZoneScope {
  ZoneScope._();

  static int? current;

  /// فلتر PostgREST لـ .or(): منطقتي + اللي من غير منطقة (عام). null = من غير فلتر.
  static String? get orFilter => current == null ? null : 'zone_id.eq.$current,zone_id.is.null';
}
