import '../../auth/data/models/app_user.dart';

/// عقد عمليات المدير العامة: المستخدمين والأدوار والإشعارات.
abstract interface class AdminRepository {
  /// كل المستخدمين (الأعلى نقاطًا الأول).
  Future<List<AppUser>> fetchUsers();

  /// تغيير دور مستخدم (user | manager).
  Future<void> setRole(String userId, String role);

  /// ids اليوزرز اللي نزّلوا تشكيلة للماتش ده.
  Future<Set<String>> pickedUserIds(String matchId);

  /// إشعار: بيتسجّل جوه التطبيق + push.
  /// userIds فاضية = للكل. بيرجّع true لو الـ push اتبعت.
  Future<bool> notify({
    required String title,
    required String body,
    String kind = 'event',
    String? matchId,
    List<String>? userIds,
  });
}
