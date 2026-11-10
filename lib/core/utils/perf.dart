import 'package:flutter/foundation.dart';

import '../logging/app_log.dart';

/// بيقيس وقت تحميل حاجة ويسجّله (debug) (في الـ debug بس — مالوش أي أثر في نسخة المتجر).
/// مثال في الكونسول:  ⏱ home: 320ms
Future<T> timed<T>(String label, Future<T> Function() run) async {
  if (!kDebugMode) return run();
  final sw = Stopwatch()..start();
  try {
    return await run();
  } finally {
    AppLog.debug('perf.timed', fields: {'label': label, 'ms': sw.elapsedMilliseconds});
  }
}
