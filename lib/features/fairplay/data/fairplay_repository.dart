/// بلاغ مراهنات (للأدمن): مين بلّغ ومنين، على مين، والتفاصيل، وحالته.
typedef BettingReport = ({
  String id,
  String reporter,
  String zone,
  String suspect,
  String details,
  String status, // open | investigating | proven | dismissed
  DateTime createdAt,
  String? suspectUserId, // لو البلاغ من صفحة يوزر بعينه
  bool suspectBanned,
});

/// عقد منع المراهنات: البلاغ (أي يوزر) + مراجعته (الأدمن).
abstract interface class FairPlayRepository {
  /// يبلّغ إن حد (مدير أو حد في منطقة) بيستخدم الأبلكيشن في مراهنات.
  /// [userId] لو البلاغ من صفحة يوزر بعينه.
  Future<void> report(String suspect, String details, {String? userId});

  /// (أدمن) كل البلاغات — المفتوحة الأول.
  Future<List<BettingReport>> adminReports();

  /// (أدمن) قرار البلاغ: investigating · proven · dismissed.
  /// لو اتثبت والبلاغ على حساب بعينه السيرفر بيعمله بان نهائي — بيرجّع true لو الحساب اتوقف.
  Future<bool> setStatus(String id, String status);
}
