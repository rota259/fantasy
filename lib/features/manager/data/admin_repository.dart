import '../../auth/data/models/app_user.dart';

/// عقد عمليات المدير العامة: المستخدمين والأدوار والإشعارات.
abstract interface class AdminRepository {
  /// كل المستخدمين (الأعلى نقاطًا الأول).
  Future<List<AppUser>> fetchUsers();

  /// تغيير دور مستخدم (user | manager).
  Future<void> setRole(String userId, String role);

  /// ids اليوزرز اللي نزّلوا تشكيلة للماتش ده.
  Future<Set<String>> pickedUserIds(String matchId);

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
