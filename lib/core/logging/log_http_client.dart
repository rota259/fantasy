import 'dart:async';

import 'package:http/http.dart' as http;

import 'app_log.dart';
import 'log_entry.dart';

/// كل طلب للسيرفر (قاعدة البيانات · الدخول · الصور · الـ Edge Functions) بيعدّي من هنا:
///   • بياخد رقم طلب X-Request-ID (نفس الرقم بيتسجّل عندنا وبيوصل السيرفر) — بلاغ واحد بالرقم ده = القصة كلها
///   • بيتسجّل: الطريقة + المسار (من غير أي قيم) + الكود + المدة — عمرنا ما بنسجّل محتوى الطلب أو الرد
///   • الناجح السريع debug (مبيتبعتش) — السيرفر عنده سجل كل الطلبات أصلًا · البطيء والفاشل بيتبعتوا
class LogHttpClient extends http.BaseClient {
  LogHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();
  final http.Client _inner;

  static const slowMs = 4000;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final id = request.headers['X-Request-ID'] ?? LogIds.make('req');
    request.headers['X-Request-ID'] = id;
    final route = '${request.method} ${routeOf(request.url)}';
    final quiet = route.contains('/rpc/log_events'); // إرسال السجلات نفسه مبيتسجّلش (وإلا هتلف على نفسها)
    final sw = Stopwatch()..start();
    try {
      final res = await _inner.send(request);
      if (!quiet) _record(route, id, res.statusCode, sw.elapsedMilliseconds);
      return res;
    } catch (e) {
      if (!quiet) {
        // النت قاطع أو السيرفر مش بيرد: حاجة متوقعة على الموبايل → warn مش error
        final offline = e is TimeoutException || e is http.ClientException || '${e.runtimeType}'.contains('Socket');
        AppLog.log(
          offline ? LogLevel.warn : LogLevel.error,
          offline ? 'http.unreachable' : 'http.failed',
          error: e,
          route: route,
          requestId: id,
          durationMs: sw.elapsedMilliseconds,
        );
      }
      rethrow;
    }
  }

  void _record(String route, String id, int status, int ms) {
    final (LogLevel level, String event) = switch (status) {
      >= 500 => (LogLevel.error, 'http.error'),
      401 || 403 => (LogLevel.warn, 'authz.denied'),
      429 => (LogLevel.warn, 'http.rate_limited'),
      >= 400 => (LogLevel.info, 'http.rejected'), // السيرفر رفض إدخال غلط — ده شغله
      _ => ms > slowMs ? (LogLevel.warn, 'http.slow') : (LogLevel.debug, 'http.request'),
    };
    AppLog.log(level, event, route: route, requestId: id, status: status, durationMs: ms);
  }

  /// المسار من غير أي بيانات: من غير الـ query، وأي جزء شكله id أو اسم ملف بيبقى «:id».
  static String routeOf(Uri url) {
    final parts = url.pathSegments.where((s) => s.isNotEmpty).map((s) {
      final looksLikeId = s.length > 20 || RegExp(r'\d{4,}').hasMatch(s) || s.contains('.') || s.contains('@');
      return looksLikeId ? ':id' : s;
    });
    final path = '/${parts.join('/')}';
    return path.length > 110 ? path.substring(0, 110) : path;
  }

  @override
  void close() => _inner.close();
}
