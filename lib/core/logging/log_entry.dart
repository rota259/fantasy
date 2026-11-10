import 'dart:math';

import 'log_redact.dart';

/// مستويات السجل — من الأقل أهمية للأعلى.
///   debug تشخيص للتطوير (مقفول في النسخة المنشورة) · info حدث طبيعي مهم · warn حاجة غريبة اتعالجت
///   error عملية فشلت ويوزر اتأثر · fatal الأبلكيشن مش قادر يكمّل
enum LogLevel {
  debug,
  info,
  warn,
  error,
  fatal;

  static LogLevel? parse(Object? name) {
    for (final l in values) {
      if (l.name == '$name'.toLowerCase().trim()) return l;
    }
    return null;
  }
}

/// أرقام تعريف عشوائية: للجلسة (ses_) ولكل طلب للسيرفر (req_).
abstract final class LogIds {
  static final _rnd = Random.secure();

  static String make(String prefix) {
    final hex = List.generate(8, (_) => _rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    return '${prefix}_$hex';
  }
}

/// سطر سجل واحد — بيانات منظّمة (JSON) مش جملة.
class LogEntry {
  LogEntry({
    required this.level,
    required this.event,
    required this.env,
    required this.version,
    required this.sessionId,
    this.message,
    this.userId,
    this.requestId,
    this.route,
    this.status,
    this.durationMs,
    this.errorType,
    this.errorStack,
    Map<String, Object?>? fields,
    DateTime? at,
  }) : fields = fields ?? const {},
       at = (at ?? DateTime.now()).toUtc();

  final LogLevel level;
  final String event; // اسم ثابت بنقط: auth.login.failed
  final String env, version, sessionId;
  final String? message, userId, requestId, route, errorType, errorStack;
  final int? status, durationMs;
  final Map<String, Object?> fields;
  final DateTime at;

  /// UTC بصيغة ISO-8601 بالملّي ثانية: 2026-10-13T15:27:04.118Z
  static String stamp(DateTime utc) {
    String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return '${p(utc.year, 4)}-${p(utc.month)}-${p(utc.day)}T${p(utc.hour)}:${p(utc.minute)}:${p(utc.second)}'
        '.${p(utc.millisecond, 3)}Z';
  }

  Map<String, Object?> toJson() => {
    'timestamp': stamp(at),
    'level': level.name,
    'service': 'app',
    'env': env,
    'version': version,
    'event': event,
    'session_id': sessionId,
    if (message != null) 'message': LogRedact.text(message),
    if (userId != null) 'user_id': userId,
    if (requestId != null) 'request_id': requestId,
    if (route != null) 'route': route,
    if (status != null) 'status': status,
    if (durationMs != null) 'duration_ms': durationMs,
    if (errorType != null) 'error_type': errorType,
    if (errorStack != null) 'error_stack': LogRedact.text(errorStack, max: 4000),
    if (fields.isNotEmpty) 'fields': fields,
  };
}
