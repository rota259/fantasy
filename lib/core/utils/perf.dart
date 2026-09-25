import 'package:flutter/foundation.dart';

/// بيقيس وقت تحميل حاجة ويطبعه في الكونسول (في الـ debug بس — مالوش أي أثر في نسخة المتجر).
/// مثال في الكونسول:  ⏱ home: 320ms
Future<T> timed<T>(String label, Future<T> Function() run) async {
  if (!kDebugMode) return run();
  final sw = Stopwatch()..start();
  try {
    return await run();
  } finally {
    debugPrint('⏱ $label: ${sw.elapsedMilliseconds}ms');
  }
}
