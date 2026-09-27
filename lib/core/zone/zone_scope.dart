/// منطقة اليوزر الحالي (بتتحدد بعد الدخول في AppRoot).
/// الـ repositories بتفلتر بيها اللي اليوزر بيشوفه: ماتشات ولاعيبة ونجم وتشكيلة منطقته بس.
abstract final class ZoneScope {
  ZoneScope._();

  static int? current;

  /// فلتر PostgREST لـ .or(): منطقتي بس. null = من غير فلتر (حساب من غير منطقة).
  static String? get orFilter => current == null ? null : 'zone_id.eq.$current';
}
