/// بلاغ مراهنات (للأدمن): مين بلّغ ومنين، على مين، والتفاصيل، وحالته.
typedef BettingReport = ({
  String id,
  String reporter,
  String zone,
  String suspect,
  String details,
  String status, // open | investigating | proven | dismissed
  DateTime createdAt,
});

/// عقد منع المراهنات: البلاغ (أي يوزر) + مراجعته (الأدمن).
abstract interface class FairPlayRepository {
  /// يبلّغ إن حد (مدير أو حد في منطقة) بيستخدم الأبلكيشن في مراهنات.
  Future<void> report(String suspect, String details);

  /// (أدمن) كل البلاغات — المفتوحة الأول.
  Future<List<BettingReport>> adminReports();

  /// (أدمن) حالة البلاغ: investigating · proven · dismissed.
  Future<void> setStatus(String id, String status);
}
