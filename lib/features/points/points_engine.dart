/// أنواع الأحداث وأساميها وقيمتها الاسمية (للعرض بس).
/// الحساب الحقيقي في السيرفر (fn_score_points / fn_pmp) عشان القواعد متتكتبش مرتين:
///   هدف +٥ (الحارس +٨) · أسيست +٣ · هاتريك أهداف +٦ وبعده الهدف +٧ · هاتريك أسيست +٤ وبعده الأسيست +٥
///   كل ٤ تصديات +١ · صد بلنتي +٤ · كلين شيت للحارس (استقبل ٤ أو أقل) +٨ أوتوماتيك
///   كل ٥ تدخلات دفاعية +١ · ضيّع بلنتي −٣ · سب الدين −٥ · جول عكسي −٢ · رجل المباراة +٣
///   كارت أصفر −١ · كارت أحمر −٢ · التبديل مالوش نقط
abstract final class PointsEngine {
  PointsEngine._();

  /// الأحداث اللي المدير بيسجّلها (رجل المباراة بتصويت الجمهور، والكلين شيت من النتيجة).
  static const managerEvents = [
    ('goal', 'جول'),
    ('assist', 'أسيست'),
    ('save', 'تصدّي'),
    ('tackle', 'تدخّل دفاعي'),
    ('penaltySave', 'صد بلنتي'),
    ('penaltyMiss', 'ضيّع بلنتي'),
    ('ownGoal', 'جول عكسي'),
    ('yellowCard', 'كارت أصفر 🟨'),
    ('redCard', 'كارت أحمر 🟥'),
    ('insult', 'سب الدين'),
    ('sub', 'تبديل 🔁'),
  ];

  /// الأحداث المهمة اللي بتظهر في ملخص الماتش تحت النتيجة.
  static const highlights = {'goal', 'ownGoal', 'penaltySave', 'penaltyMiss', 'yellowCard', 'redCard', 'sub', 'insult'};

  /// أيقونة الحدث في الملخص والتايملاين.
  static String eventIcon(String type) => switch (type) {
    'goal' => '⚽',
    'ownGoal' => '⚽🔙',
    'assist' => '🎯',
    'save' => '🧤',
    'penaltySave' => '🧤',
    'penaltyMiss' => '❌',
    'tackle' => '🛡',
    'yellowCard' => '🟨',
    'redCard' => '🟥',
    'sub' => '🔁',
    'insult' => '🚫',
    'motm' => '⭐',
    _ => '•',
  };

  /// القيمة الاسمية لحدث واحد (التصدّي والتدخّل بيتجمّعوا: ٤ تصديات / ٥ تدخلات = نقطة).
  static int eventPoints(String type, String position) => switch (type) {
    'goal' => position == 'GK' ? 8 : 5,
    'assist' => 3,
    'penaltySave' => 4,
    'penaltyMiss' => -3,
    'insult' => -5,
    'ownGoal' => -2,
    'motm' => 3,
    'yellowCard' => -1,
    'redCard' => -2,
    _ => 0,
  };

  /// وصف الحدث بالعربي للبث الحي.
  static String eventLabel(String type) => switch (type) {
    'goal' => 'جوووول',
    'assist' => 'تمريرة حاسمة',
    'save' => 'تصدّي',
    'tackle' => 'تدخّل دفاعي',
    'penaltySave' => 'صدّ بلنتي',
    'penaltyMiss' => 'ضيّع بلنتي',
    'ownGoal' => 'جول عكسي',
    'insult' => 'سب — خصم ٥',
    'motm' => 'رجل المباراة ⭐',
    'yellowCard' => 'كارت أصفر',
    'redCard' => 'كارت أحمر',
    'sub' => 'تبديل',
    _ => type,
  };
}
