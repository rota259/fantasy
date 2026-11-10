import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_log.dart';
import 'log_shipper.dart';

/// تشغيل نظام السجلات — بيتنادى مرة واحدة في main() قبل أي حاجة.
///   • النسخة على كل سطر (عشان نربط أي مشكلة بالإصدار اللي ظهرت فيه)
///   • أي خطأ محدش مسكه (في الرسم أو في الخلفية) بيتسجّل مرة واحدة بالـ stack trace كامل
///   • في النسخة المنشورة: الخطأ ميقفلش الأبلكيشن، ومكان الجزء اللي باظ بيظهر مربع صغير بدل شاشة رمادي
///   • لما الأبلكيشن يروح الخلفية: اللي لسه متبعتش بيتبعت
abstract final class Logging {
  static bool _installed = false;

  static Future<void> install() async {
    if (_installed) return;
    _installed = true;
    try {
      final info = await PackageInfo.fromPlatform();
      AppLog.version = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    AppLog.sink = LogShipper.instance.add;
    await LogShipper.instance.start();

    final present = FlutterError.onError;
    FlutterError.onError = (details) {
      AppLog.error(
        'flutter.error',
        error: details.exception,
        stack: details.stack,
        fields: {'library': details.library, 'context': details.context?.toDescription()},
      );
      if (kDebugMode) present?.call(details); // في التطوير: الخطأ يبان كامل زي العادي
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLog.fatal('dart.uncaught', error: error, stack: stack);
      return !kDebugMode;
    };
    if (!kDebugMode) ErrorWidget.builder = (_) => const _BrokenPart();

    WidgetsBinding.instance.addObserver(_Lifecycle());
    AppLog.info(
      'app.start',
      fields: {'platform': defaultTargetPlatform.name, 'log_level': AppLog.level.name, 'debug': kDebugMode},
    );
  }
}

class _Lifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) LogShipper.instance.flush();
  }
}

/// بديل الشاشة الرمادي: جزء من الشاشة باظ — الباقي شغّال.
class _BrokenPart extends StatelessWidget {
  const _BrokenPart();

  @override
  Widget build(BuildContext context) => const Material(
    color: Colors.transparent,
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'حصلت مشكلة هنا — ارجع وجرّب تاني',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF8A8F8C)),
        ),
      ),
    ),
  );
}
