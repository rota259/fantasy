/// أنواع الأحداث وأساميها وقيمتها الاسمية (للعرض بس).
/// الحساب الحقيقي في السيرفر (fn_score_points / fn_pmp) عشان القواعد متتكتبش مرتين:
///   هدف +٥ (الحارس +٨) · أسيست +٣ · هاتريك أهداف +٦ وبعده الهدف +٧ · هاتريك أسيست +٤ وبعده الأسيست +٥
///   كل ٤ تصديات +١ · صد بلنتي +٤ · كلين شيت للحارس (استقبل ٤ أو أقل) +٨ أوتوماتيك
///   كل ٥ تدخلات دفاعية +١ · ضيّع بلنتي −٣ · سب الدين −٥ · جول عكسي −٢ · رجل المباراة +٣
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
    ('insult', 'سب الدين'),
  ];

  /// القيمة الاسمية لحدث واحد (التصدّي والتدخّل بيتجمّعوا: ٤ تصديات / ٥ تدخلات = نقطة).
  static int eventPoints(String type, String position) => switch (type) {
    'goal' => position == 'GK' ? 8 : 5,
    'assist' => 3,
    'penaltySave' => 4,
    'penaltyMiss' => -3,
    'insult' => -5,
    'ownGoal' => -2,
    'motm' => 3,
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
    _ => type,
  };
}
