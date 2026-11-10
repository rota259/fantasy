import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/squad/data/profile_repository.dart';
import '../logging/app_log.dart';
import 'device_notify.dart';

/// خدمة إشعارات FCM: تهيئة + إذن + تسجيل التوكن + الاشتراك في إشعارات الكل.
abstract final class NotificationService {
  NotificationService._();

  /// topic اللي السيرفر بيبعتله الإشعارات العامة (طلب واحد لكل اليوزرز).
  static const _allTopic = 'all';

  /// topic منطقة اليوزر (إشعارات ماتشات منطقته) — `zone_ID`.
  static String? _zoneTopic;

  /// بتتنادى مرة في main() — بتهيّئ Firebase وتطلب إذن الإشعارات.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      // من غير await: نافذة الإذن متوقفش فتح الأبلكيشن
      unawaited(FirebaseMessaging.instance.requestPermission().then((_) {}, onError: (_) {}));
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
      AppLog.info('push.token.registered', fields: {'has_token': token != null});
    } catch (e) {
      // من غير توكن السيرفر ملوش عنوان يبعتله — ولا إشعار هيوصل الموبايل ده
      final cause = await DeviceNotify.fcmError(); // السبب الحقيقي (Flutter بيوصّل أول سطر بس)
      AppLog.error('push.token.failed', error: e, message: cause ?? '$e');
    }
  }

  /// الاشتراك في إشعارات منطقة اليوزر (وإلغاء القديمة لو غيّرها).
  static Future<void> setZone(int? zoneId) async {
    final topic = zoneId == null ? null : 'zone_$zoneId';
    if (topic == _zoneTopic) return;
    try {
      final messaging = FirebaseMessaging.instance;
      if (_zoneTopic != null) await messaging.unsubscribeFromTopic(_zoneTopic!);
      if (topic != null) await messaging.subscribeToTopic(topic);
      _zoneTopic = topic;
    } catch (_) {}
  }

  static bool _tapsWired = false;

  /// الضغط على push: والأبلكيشن في الخلفية، أو مقفول وفتح بيه — [onTap] بياخد data الإشعار (link · match_id).
  static Future<void> listenTaps(void Function(Map<String, dynamic> data) onTap) async {
    if (_tapsWired) return;
    _tapsWired = true;
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((m) => onTap(m.data));
      unawaited(DeviceNotify.listenTaps(onTap)); // الإشعارات اللي الأبلكيشن حطها في الشريط وهو مفتوح
      final first = await FirebaseMessaging.instance.getInitialMessage();
      if (first != null) onTap(first.data);
    } catch (_) {}
  }

  /// عند الخروج: الجهاز ميستقبلش إشعارات الحساب ده تاني.
  static Future<void> unregister() async {
    try {
      await setZone(null);
      await FirebaseMessaging.instance.unsubscribeFromTopic(_allTopic);
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
