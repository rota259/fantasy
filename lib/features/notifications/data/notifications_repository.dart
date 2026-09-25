import 'models/app_notification.dart';

/// عقد إشعارات التطبيق.
abstract interface class NotificationsRepository {
  /// آخر الإشعارات (الأحدث الأول).
  Future<List<AppNotification>> fetchRecent();

  /// (مدير) تسجيل إشعار جديد يظهر لكل اليوزرز.
  Future<void> add({required String title, required String body, String kind = 'event', String? matchId});
}
