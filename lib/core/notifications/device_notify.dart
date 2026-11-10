import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import '../logging/app_log.dart';

/// قناة إشعار على الموبايل (من أندرويد نفسه).
class NotifyChannelInfo {
  const NotifyChannelInfo(this.id, this.name, this.importance, this.sound);
  final String id, name;
  final int importance; // ٠ مقفولة · ٣ عادي · ٤ بتظهر فوق الشاشة بصوت
  final bool sound;

  bool get ok => importance >= 4 && sound;
}

/// حالة إشعارات الموبايل ده.
class DeviceNotifyStatus {
  const DeviceNotifyStatus({
    this.enabled = true,
    this.channels = const [],
    this.manufacturer = '',
    this.batteryOptimized = false,
  });

  final bool enabled; // الإشعارات مسموحة للأبلكيشن
  final List<NotifyChannelInfo> channels;
  final String manufacturer;
  final bool batteryOptimized; // توفير البطارية ممكن يأخّر الإشعار والأبلكيشن مقفول

  /// شركات بتقفل التشغيل في الخلفية للأبلكيشنات الجديدة (لازم تفعّل «التشغيل التلقائي» بإيدك).
  bool get strictMaker => const [
    'xiaomi',
    'redmi',
    'poco',
    'oppo',
    'realme',
    'vivo',
    'huawei',
    'honor',
    'oneplus',
  ].any(manufacturer.contains);

  List<NotifyChannelInfo> get broken => channels.where((c) => !c.ok).toList();
  bool get allGood => enabled && broken.isEmpty && !batteryOptimized;
}

/// فحص وإصلاح إشعارات الجهاز (android: NotifyChannel.kt) — على غير أندرويد كله بيرجع «تمام».
abstract final class DeviceNotify {
  static const _ch = MethodChannel('khomasi/notify');

  static Future<DeviceNotifyStatus> status() async {
    try {
      final m = Map<String, dynamic>.from(await _ch.invokeMethod('status') as Map);
      final status = DeviceNotifyStatus(
        enabled: m['enabled'] == true,
        manufacturer: '${m['manufacturer'] ?? ''}',
        batteryOptimized: m['batteryOptimized'] == true,
        channels: [
          for (final c in (m['channels'] as List? ?? const []))
            NotifyChannelInfo(
              '${(c as Map)['id']}',
              '${c['name']}',
              (c['importance'] as num?)?.toInt() ?? 0,
              c['sound'] == true,
            ),
        ],
      );
      AppLog.info(
        'push.device.status',
        fields: {
          'enabled': status.enabled,
          'broken_channels': status.broken.length,
          'battery_optimized': status.batteryOptimized,
          'maker': status.manufacturer,
        },
      );
      return status;
    } catch (_) {
      return const DeviceNotifyStatus();
    }
  }

  /// إذن الإشعارات (أندرويد ١٣+ وآيفون) — ولو اترفض قبل كده بنفتح الإعدادات.
  static Future<void> requestPermission() async {
    try {
      final s = await FirebaseMessaging.instance.requestPermission();
      if (s.authorizationStatus == AuthorizationStatus.denied) await openApp();
    } catch (_) {
      await openApp();
    }
  }

  /// والأبلكيشن مفتوح: الإشعار بيتحط في شريط الإشعارات كمان (Firebase مبيحطوش وقتها).
  /// قناة هادية — من غير صوت ولا ظهور فوق الشاشة، لأن الأبلكيشن بيعرض شريطه وبيشغّل النغمة بنفسه.
  static Future<void> show(String title, String body, Map<String, dynamic> data) => _call('show', {
    'title': title,
    'body': body,
    'link': '${data['link'] ?? ''}',
    'match_id': '${data['match_id'] ?? ''}',
  });

  /// الضغط على إشعار من بتوعنا: وهو في الخلفية ([onTap] على طول) أو بعد ما يتفتح من الأول (launchTap).
  static Future<void> listenTaps(void Function(Map<String, dynamic> data) onTap) async {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'tap') onTap(Map<String, dynamic>.from(call.arguments as Map));
    });
    try {
      final first = await _ch.invokeMethod('launchTap');
      if (first is Map) onTap(Map<String, dynamic>.from(first));
    } catch (_) {}
  }

  /// سبب فشل توكن Firebase بالكامل (null لو التوكن شغّال أو مش أندرويد).
  static Future<String?> fcmError() async {
    try {
      final m = Map<String, dynamic>.from(await _ch.invokeMethod('fcmProbe') as Map);
      return m['ok'] == true ? null : '${m['error']}';
    } catch (_) {
      return null;
    }
  }

  static Future<void> openApp() => _call('openApp');
  static Future<void> openChannel(String id) => _call('openChannel', {'id': id});
  static Future<void> openAutostart() => _call('openAutostart');
  static Future<void> openBattery() => _call('openBattery');

  static Future<void> _call(String method, [Map<String, Object?>? args]) async {
    try {
      await _ch.invokeMethod(method, args);
    } catch (_) {}
  }
}
