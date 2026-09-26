/// علامات الغرابة اللي السيرفر بيحطها على الماتش (fn_match_flags).
/// مش ممنوعات — بس الماتش المعلّم عليه لازم الفريقين يأكدوه صراحةً.
abstract final class MatchFlags {
  MatchFlags._();

  static String label(String flag) => switch (flag) {
    'score_mismatch' => 'الأهداف المسجّلة مش نفس النتيجة',
    'big_margin' => 'فرق ١٠ أهداف أو أكتر',
    'organizer_stats' => 'المنظّم نفسه عمل ٣ أهداف/أسيست أو أكتر',
    'new_organizer' => 'منظّم جديد (أقل من ٥ ماتشات معتمدة)',
    'late_edit' => 'اتعدّل بعد ما الماتش خلص',
    _ => flag,
  };
}
