import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/squad/data/profile_repository.dart';

/// خدمة إشعارات FCM: تهيئة + إذن + تسجيل التوكن للمستخدم.
abstract final class NotificationService {
  NotificationService._();

  /// بتتنادى مرة في main() — بتهيّئ Firebase وتطلب إذن الإشعارات.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {
      // بيفشل بهدوء على المنصّات اللي مفيهاش إعداد Firebase (زي الويب).
    }
  }

  /// بتخزّن توكن الجهاز للمستخدم بعد تسجيل الدخول + بتتابع أي تجديد للتوكن.
  static Future<void> registerToken(String userId, ProfileRepository repo) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await repo.saveFcmToken(userId, token);
      // التوكن ممكن يتجدّد — نخزّن الجديد تلقائيًا.
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        repo.saveFcmToken(userId, t).catchError((_) {});
      });
    } catch (_) {}
  }
}
