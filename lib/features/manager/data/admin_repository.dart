import '../../auth/data/models/app_user.dart';
import 'models/admin_log_entry.dart';

/// أرقام لوحة الأدمن (محسوبة في السيرفر من غير ما نحمّل حاجة).
typedef AdminCounts = ({int users, int admins, int managers, int players, int upcoming, int finished});

/// عقد عمليات الأدمن: المستخدمين والأدوار والإشعارات.
abstract interface class AdminRepository {
  /// المستخدمين (الأعلى نقاطًا الأول) — بحث بالاسم/الإيميل/الموبايل ودور اختياري، بحد أقصى [limit].
  Future<List<AppUser>> fetchUsers({String? query, String? role, int limit = 100});

  Future<AdminCounts> counts();

  /// مدير منطقة ↔ يوزر (user | organizer). الأدمن بيتضاف من Supabase بس.
  Future<void> setRole(String userId, String role);

  /// حظر / فك حظر (المحظور بيتفرّج بس).
  Future<void> setActive(String userId, bool active);

  /// نقل يوزر/مدير لمنطقة تانية.
  Future<void> setZone(String userId, int zoneId);

  /// سجل عمليات الأدمنز (الأحدث الأول).
  Future<List<AdminLogEntry>> log();

  /// كام يوزر حفظ تشكيلة للجولة دي (بنهايتها).
  Future<int> roundPickerCount(DateTime roundEnd);

  /// تذكير بتشكيلة الجولة لأهل منطقة الماتش (إشعار واحد).
  Future<void> remindRound(String matchId);

  /// إشعار: بيتسجّل جوه التطبيق، والداتابيز بتبعته push لوحدها.
  /// userIds فاضية = للكل.
  Future<void> notify({
    required String title,
    required String body,
    String kind = 'event',
    String? matchId,
    List<String>? userIds,
  });
}
