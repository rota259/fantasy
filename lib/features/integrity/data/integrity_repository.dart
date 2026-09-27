import 'models/organizer_request.dart';
import 'models/pending_review.dart';
import 'models/review_case.dart';

/// عقد نزاهة الماتشات: تأكيد اللاعيبة + حكم الأدمن + طلبات المديرين.
abstract interface class IntegrityRepository {
  /// الماتشات اللي مستنية تأكيدي كلاعب موثّق.
  Future<List<PendingReview>> myPendingReviews();

  /// ✅ / ❌ على ورقة الماتش — بيرجّع ok · approved · disputed.
  Future<String> reviewMatch(String matchId, {required bool ok, String? note});

  /// (أدمن) الاعتراضات والماتشات المعلّم عليها.
  Future<List<ReviewCase>> reviewQueue();

  /// (أدمن) approve · void · reopen.
  Future<void> resolve(String matchId, String action);

  /// (مدير/أدمن) إشعار "التشكيلة نزلت".
  Future<void> notifyLineup(String matchId);

  /// آخر طلب تنظيم ليا (null = مقدّمتش).
  Future<OrganizerRequest?> myOrganizerRequest(String userId);

  Future<void> requestOrganizer(String userId, String? note);

  /// (أدمن) الطلبات المعلّقة.
  Future<List<OrganizerRequest>> pendingOrganizerRequests();

  /// (أدمن) موافقة/رفض.
  Future<void> reviewOrganizerRequest(String requestId, bool approve);
}
