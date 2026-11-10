import 'package:fantasy_5omasi/core/logging/app_log.dart';
import 'package:fantasy_5omasi/core/logging/log_entry.dart';
import 'package:fantasy_5omasi/core/logging/log_http_client.dart';
import 'package:fantasy_5omasi/core/logging/log_redact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('التنضيف (redaction)', () {
    test('الحقول الحسّاسة بتتشال', () {
      final f = LogRedact.fields({
        'password': 'hunter2',
        'access_token': 'abc',
        'Authorization': 'Bearer x',
        'apiKey': 'k',
        'code': '123456',
        'otp': '9',
        'screen': 'pick',
        'count': 5,
        'ok': true,
      });
      expect(f.keys, unorderedEquals(['screen', 'count', 'ok']));
    });

    test('الإيميل والرقم بيتغطّوا جوه أي نص', () {
      final t = LogRedact.text('فشل لـ anas.rashwan@gmail.com ورقمه 01012345678');
      expect(t, isNot(contains('anas.rashwan')));
      expect(t, isNot(contains('01012345678')));
      expect(t, contains('a***@gmail.com'));
    });

    test('التوكن (JWT) بيتشال من النص', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abcdefghijklmnop';
      expect(LogRedact.text('Bearer $jwt'), 'Bearer [token]');
    });

    test('النص الطويل بيتقص', () => expect(LogRedact.text('x' * 900).length, lessThan(510)));
  });

  group('شكل السطر', () {
    final entry = LogEntry(
      level: LogLevel.error,
      event: 'http.error',
      env: 'prod',
      version: '1.0.0+1',
      sessionId: 'ses_1',
      requestId: 'req_9f2a1c',
      route: 'POST /rest/v1/rpc/save_round_picks',
      status: 500,
      durationMs: 1234,
      at: DateTime.utc(2026, 10, 13, 15, 27, 4, 118),
    );

    test('الوقت UTC بصيغة ISO-8601 بالملّي ثانية', () {
      expect(entry.toJson()['timestamp'], '2026-10-13T15:27:04.118Z');
    });

    test('الحقول الأساسية على كل سطر', () {
      final j = entry.toJson();
      for (final k in ['timestamp', 'level', 'service', 'env', 'version', 'event', 'session_id', 'request_id']) {
        expect(j.containsKey(k), isTrue, reason: k);
      }
      expect(j['level'], 'error');
      expect(j['status'], 500);
      expect(j['duration_ms'], 1234);
    });

    test('أرقام الطلبات مختلفة', () => expect(LogIds.make('req'), isNot(LogIds.make('req'))));
  });

  group('مسار الطلب من غير بيانات', () {
    test('من غير query ومن غير ids', () {
      final u = Uri.parse(
        'https://x.supabase.co/rest/v1/profiles?id=eq.3f2b8c1e-aaaa-bbbb-cccc-1234567890ab&email=eq.a@b.com',
      );
      expect(LogHttpClient.routeOf(u), '/rest/v1/profiles');
    });

    test('مسار ملف في التخزين', () {
      final u = Uri.parse(
        'https://x.supabase.co/storage/v1/object/avatars/3f2b8c1e-aaaa-bbbb-cccc-1234567890ab/me.jpg',
      );
      expect(LogHttpClient.routeOf(u), '/storage/v1/object/avatars/:id/:id');
    });
  });

  group('المستويات', () {
    test('اللي تحت المستوى مبيتسجّلش', () {
      final got = <String>[];
      AppLog.sink = (e) => got.add(e.event);
      AppLog.level = LogLevel.warn;
      AppLog.info('a.info');
      AppLog.warn('a.warn');
      AppLog.error('a.error', error: StateError('x'));
      expect(got, ['a.warn', 'a.error']);
    });

    test('نفس الخطأ ٣ مرات في الجلسة كفاية', () {
      final got = <String>[];
      AppLog.sink = (e) => got.add(e.event);
      AppLog.level = LogLevel.debug;
      for (var i = 0; i < 10; i++) {
        AppLog.error('loop.error', error: StateError('same'));
      }
      expect(got.length, 3);
    });

    test('المستوى من السيرفر', () {
      AppLog.applyRemoteLevel('error');
      expect(AppLog.level, LogLevel.error);
      AppLog.applyRemoteLevel('nonsense');
      expect(AppLog.level, LogLevel.error);
    });
  });
}
