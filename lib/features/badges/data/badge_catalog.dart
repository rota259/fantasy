import '../../../core/theme/app_colors.dart';

/// تعريف شارة: الاسم + الوصف + حدود المستويات (برونز/فضة/دهب).
/// الحدود نفس fn_badge_tier في السيرفر (السيرفر هو اللي بيدّي الشارة، ده للعرض والتقدّم).
class BadgeDef {
  const BadgeDef(
    this.key,
    this.name,
    this.emoji,
    this.description,
    this.tiers, {
    required this.group,
    this.secret = false,
    this.lowerIsBetter = false,
  });

  final String key;
  final String name;
  final String emoji;
  final String description; // فيها {n} = الحد
  final List<int> tiers; // [برونز، فضة، دهب]
  final String group;
  final bool secret; // مش باينة غير لما تاخدها
  final bool lowerIsBetter; // من الأوائل: الرقم الأصغر أحسن

  /// المستوى لقيمة معيّنة (0 = لسه).
  int tierFor(int value) {
    if (lowerIsBetter) {
      if (value <= 0) return 0;
      return tiers.where((t) => value <= t).length;
    }
    return tiers.where((t) => value >= t).length;
  }

  /// الحد اللي جاي (null لو وصل للدهب).
  int? nextTarget(int tier) => tier >= tiers.length ? null : tiers[tier];

  String describe(int tier) => description.replaceAll('{n}', '${tiers[tier.clamp(0, tiers.length - 1)]}');
}

abstract final class BadgeCatalog {
  BadgeCatalog._();

  static const tierNames = ['', 'برونز', 'فضة', 'دهب'];
  static const tierColors = [AppColors.neutral300, AppColors.bronze, AppColors.silver, AppColors.gold];

  static const all = <BadgeDef>[
    // 🔥 الاستمرار
    BadgeDef('streak', 'مش بيفوّت', '🔥', 'عملت تشكيلة {n} جولات ورا بعض', [5, 10, 25], group: 'الاستمرار'),
    BadgeDef('addict', 'المدمن', '💉', '{n} ماتش ورا بعض من غير ما تفوّت', [10, 25, 50], group: 'الاستمرار'),
    BadgeDef(
      'first_100',
      'من الأوائل',
      '🥇',
      'من أول {n} يوزر في الخماسي',
      [1000, 500, 100],
      group: 'الاستمرار',
      lowerIsBetter: true,
    ),
    BadgeDef('early_bird', 'صاحي بدري', '🌅', 'حفظت تشكيلتك قبل الماتش بـ ٢٤ ساعة ({n} مرة)', [
      1,
      10,
      30,
    ], group: 'الاستمرار'),
    BadgeDef(
      'last_second',
      'آخر ثانية',
      '⏱️',
      'حفظت قبل القفل بأقل من دقيقة ({n} مرة)',
      [1, 5, 15],
      group: 'الاستمرار',
      secret: true,
    ),
    // 🧠 الكابتن والاختيارات
    BadgeDef('hawk_eye', 'عين الصقر', '🦅', 'الكابتن بتاعك جاب هاتريك ({n} مرة)', [1, 3, 10], group: 'الاختيارات'),
    BadgeDef('right_captain', 'الكابتن الصح', '©️', 'الكابتن جاب أعلى نقط في الماتش ({n} مرة)', [
      1,
      5,
      15,
    ], group: 'الاختيارات'),
    BadgeDef('differential', 'ضد التيار', '🧭', 'لاعب امتلاكه أقل من ١٠٪ جابلك ١٠+ ({n} مرة)', [
      1,
      5,
      15,
    ], group: 'الاختيارات'),
    BadgeDef('golden_five', 'الخماسي الذهبي', '⭐', 'الخمسة الأساسيين كلهم جابوا نقط ({n} مرة)', [
      1,
      5,
      15,
    ], group: 'الاختيارات'),
    BadgeDef(
      'bench_betrayal',
      'الاحتياطي خاني',
      '🤦',
      'الاحتياطي جاب أكتر من الأساسيين ({n} مرة)',
      [1, 5, 15],
      group: 'الاختيارات',
      secret: true,
    ),
    BadgeDef('saviour', 'المنقذ', '🛟', 'الكابتن ملعبش والنائب جاب ٨+ ({n} مرة)', [1, 3, 10], group: 'الاختيارات'),
    // 🏆 النتايج
    BadgeDef('round_king', 'ملك الجولة', '👑', 'الأول في الجولة ({n} مرة)', [1, 3, 10], group: 'النتايج'),
    BadgeDef('day_king', 'ملك اليوم', '☀️', 'الأعلى نقط في يوم ({n} مرة)', [1, 5, 15], group: 'النتايج'),
    BadgeDef('top10', 'التوب ١٠', '🔟', 'خلّصت جولة في أول ١٠ ({n} مرة)', [1, 5, 15], group: 'النتايج'),
    BadgeDef('rocket', 'الصاروخ', '🚀', 'طلعت ٢٠ مركز في جولة واحدة ({n} مرة)', [1, 3, 10], group: 'النتايج'),
    BadgeDef('record', 'رقم قياسي', '📈', 'كسرت أعلى نقط في ماتش في تاريخ الخماسي ({n} مرة)', [
      1,
      3,
      5,
    ], group: 'النتايج'),
    BadgeDef('league_leader', 'البطل', '🏆', 'خلّصت جولة وانت الأول في دوري ({n} مرة)', [1, 5, 15], group: 'النتايج'),
    // 🎯 التوقعات والتصويت
    BadgeDef('oracle', 'العرّاف', '🔮', 'جبت نتيجة التحدّي بالظبط ({n} مرة)', [1, 3, 10], group: 'التوقعات'),
    BadgeDef('people_voice', 'صوت الشعب', '🗳️', 'صوّتت واللي اخترته كسب ({n} مرة)', [1, 5, 15], group: 'التوقعات'),
    BadgeDef('critic', 'ناقد رياضي', '📝', 'قيّمت اللاعيبة في {n} ماتش', [5, 20, 50], group: 'التوقعات'),
    // 🤝 اجتماعي
    BadgeDef('influencer', 'المؤثر', '📣', '{n} دخلوا الخماسي بكود دعوتك', [5, 15, 50], group: 'اجتماعي'),
    BadgeDef('real_captain', 'الكابتن الحقيقي', '🧢', 'دوري عملته فيه {n} عضو', [10, 25, 50], group: 'اجتماعي'),
    // ⚽ اللاعيبة الموثّقين
    BadgeDef('beloved', 'المحبوب', '❤️', 'امتلاكك عدّى ٥٠٪ في جولة ({n} مرة)', [1, 3, 10], group: 'اللاعيبة'),
    BadgeDef('people_captain', 'كابتن الشعب', '🎖️', 'أكتر لاعب اتعمل كابتن في الجولة ({n} مرة)', [
      1,
      3,
      10,
    ], group: 'اللاعيبة'),
    BadgeDef(
      'letdown',
      'خيّب الظن',
      '😂',
      '٣٠+ واحد خلّوك كابتن وجبت صفر ({n} مرة)',
      [1, 2, 3],
      group: 'اللاعيبة',
      secret: true,
    ),
  ];

  static BadgeDef? byKey(String key) {
    for (final b in all) {
      if (b.key == key) return b;
    }
    return null;
  }
}
