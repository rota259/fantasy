import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/squad/data/profile_repository.dart';

/// خدمة إشعارات FCM: تهيئة + إذن + تسجيل التوكن + الاشتراك في إشعارات الكل.
abstract final class NotificationService {
  NotificationService._();

  /// topic اللي السيرفر بيبعتله الإشعارات العامة (طلب واحد لكل اليوزرز).
  static const _allTopic = 'all';

  /// بتتنادى مرة في main() — بتهيّئ Firebase وتطلب إذن الإشعارات.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {
      // بيفشل بهدوء على المنصّات اللي مفيهاش إعداد Firebase (زي الويب).
    }
  }

  /// بعد الدخول: نخزّن توكن الجهاز (للإشعارات الموجّهة) ونشترك في إشعارات الكل.
  static Future<void> registerToken(String userId, ProfileRepository repo) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) await repo.saveFcmToken(userId, token);
      messaging.onTokenRefresh.listen((t) {
        repo.saveFcmToken(userId, t).catchError((_) {});
      });
      await messaging.subscribeToTopic(_allTopic);
    } catch (_) {}
  }

  /// عند الخروج: الجهاز ميستقبلش إشعارات الحساب ده تاني.
  static Future<void> unregister() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(_allTopic);
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
