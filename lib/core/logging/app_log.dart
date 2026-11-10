import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../supabase/supabase_config.dart';
import '../supabase/supabase_service.dart';
import 'log_entry.dart';
import 'log_redact.dart';

export 'log_entry.dart' show LogLevel;

/// الـ logger الوحيد في الأبلكيشن — أي حاجة بتتسجّل بتعدّي من هنا (ممنوع print).
///   AppLog.info('auth.login.success');
///   AppLog.error('lineup.save.failed', error: e, stack: st, fields: {'round': 12});
/// كل سطر JSON فيه: الوقت (UTC) · المستوى · البيئة · النسخة · اسم الحدث · الجلسة · اليوزر · رقم الطلب.
/// في التطوير بيتطبع سطر مقري، وفي النسخة المنشورة JSON — والمهم بيتبعت للسجل المركزي (LogShipper).
/// المستوى: --dart-define=LOG_LEVEL=debug (الافتراضي debug في التطوير و info في النسخة المنشورة)،
/// والأدمن يقدر يغيّره من غير نسخة جديدة (app_config: log_level).
abstract final class AppLog {
  static LogLevel level =
      LogLevel.parse(const String.fromEnvironment('LOG_LEVEL')) ?? (kDebugMode ? LogLevel.debug : LogLevel.info);

  static final String env = kDebugMode ? 'dev' : (SupabaseConfig.isStaging ? 'staging' : 'prod');
  static final String sessionId = LogIds.make('ses');
  static String version = 'unknown';

  /// اللي بيستقبل السطور عشان يبعتها للسجل المركزي (بيتركّب في Logging.install).
  static void Function(LogEntry entry)? sink;

  static final Map<String, int> _repeats = {};

  /// المستوى اللي الأدمن حدده من السيرفر (لو موجود وصح).
  static void applyRemoteLevel(Object? name) {
    final l = LogLevel.parse(name);
    if (l != null) level = l;
  }

  static void debug(String event, {String? message, Map<String, Object?>? fields}) =>
      log(LogLevel.debug, event, message: message, fields: fields);

  static void info(String event, {String? message, Map<String, Object?>? fields}) =>
      log(LogLevel.info, event, message: message, fields: fields);

  static void warn(String event, {String? message, Object? error, Map<String, Object?>? fields}) =>
      log(LogLevel.warn, event, message: message, error: error, fields: fields);

  static void error(String event, {Object? error, StackTrace? stack, String? message, Map<String, Object?>? fields}) =>
      log(LogLevel.error, event, message: message, error: error, stack: stack, fields: fields);

  static void fatal(String event, {Object? error, StackTrace? stack, String? message}) =>
      log(LogLevel.fatal, event, message: message, error: error, stack: stack);

  /// التسجيل نفسه — عمره ما يرمي خطأ (الـ log مينفعش يوقّع الأبلكيشن).
  static void log(
    LogLevel lvl,
    String event, {
    String? message,
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? fields,
    String? requestId,
    String? route,
    int? status,
    int? durationMs,
  }) {
    try {
      if (lvl.index < level.index) return;
      final type = error == null ? null : LogRedact.typeOf(error);
      // نفس الخطأ بيتكرر (شاشة بتترسم كل فريم مثلًا): ٣ مرات في الجلسة كفاية
      if (lvl.index >= LogLevel.error.index) {
        final key = '$event|$type|${stack?.toString().split('\n').first}';
        final n = _repeats[key] = (_repeats[key] ?? 0) + 1;
        if (n > 3) return;
      }
      final entry = LogEntry(
        level: lvl,
        event: event,
        env: env,
        version: version,
        sessionId: sessionId,
        message: message ?? (error == null ? null : LogRedact.text(error)),
        userId: _userId(),
        requestId: requestId,
        route: route,
        status: status,
        durationMs: durationMs,
        errorType: type,
        errorStack: stack?.toString(),
        fields: LogRedact.fields(fields),
      );
      _print(entry);
      sink?.call(entry);
    } catch (_) {}
  }

  /// اليوزر الحالي لو فيه (قبل تهيئة Supabase أو من غيرها: null).
  static String? _userId() {
    try {
      return SupabaseConfig.isConfigured ? SupabaseService.currentUser?.id : null;
    } catch (_) {
      return null;
    }
  }

  static void _print(LogEntry e) {
    if (!kDebugMode) return debugPrint(jsonEncode(e.toJson()));
    final t = LogEntry.stamp(e.at).substring(11, 23);
    final http = e.route == null ? '' : ' ${e.route} ${e.status ?? '-'} ${e.durationMs ?? '-'}ms';
    final extra = [
      if (e.requestId != null) e.requestId,
      if (e.message != null) e.message,
      if (e.fields.isNotEmpty) e.fields,
    ].join(' · ');
    debugPrint('[$t] ${e.level.name.toUpperCase().padRight(5)} ${e.event}$http${extra.isEmpty ? '' : ' · $extra'}');
    if (e.errorStack != null && e.level.index >= LogLevel.error.index) debugPrint(e.errorStack);
  }
}
