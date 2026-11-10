import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';

import '../logging/app_log.dart';

/// حماية وقت التشغيل (freeRASP من Talsec): بتكشف الحقن (Frida/hooks)، الـ debugger، التلاعب بالـ APK،
/// الروت، المحاكي، والتثبيت من برا المتجر.
///
/// السياسة (مقصود إنها متساهلة عشان منقفلش على يوزر عادي بالغلط):
///   • قفل الأبلكيشن: الحقن والـ debugger في نسخة الإصدار بس — دول معناهم حد بيحاول يخترق وهو شغّال.
///   • تسجيل بس: الروت · المحاكي · التلاعب · المتجر · وضع المطوّر — بتتبعت للسجلات والأدمن يشوفها.
///     (التلاعب بيتسجّل بس لحد ما بصمة مفتاح جوجل بلاي تتضاف في RASP_CERT_HASHES — وإلا نسخة المتجر هتتقفل.)
/// الحماية الحقيقية للداتا في السيرفر (RLS + الدوال) — دي طبقة زيادة بتصعّب الهجوم من الجهاز.
abstract final class Rasp {
  /// سبب القفل (null = الأبلكيشن شغّال عادي).
  static final blocked = ValueNotifier<String?>(null);

  static const _pkg = 'com.example.fantasy_5omasi';
  // بصمات SHA-256 (base64) لمفاتيح التوقيع: debug + المفتاح المحلي + مفتاح جوجل بلاي (من Play Console)
  static const _extraHashes = String.fromEnvironment('RASP_CERT_HASHES');
  static const _debugHash = 'Mo19l60rlQpAL957teZtt3tc/mpsJ2wOl+lY2F5EnV8=';
  static const _mail = String.fromEnvironment('RASP_MAIL');

  static Future<void> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Talsec.instance.attachListener(
        ThreatCallback(
          onHooks: () => _block('hooks'),
          onDebug: () => kReleaseMode ? _block('debugger') : _note('debugger'),
          onAppIntegrity: () => _note('tamper'),
          onPrivilegedAccess: () => _note('root'),
          onSimulator: () => _note('emulator'),
          onUnofficialStore: () => _note('unofficial_store'),
          onObfuscationIssues: () => _note('obfuscation'),
          onDevMode: () => _note('dev_mode'),
          onMalware: (_) => _note('malware'),
        ),
      );
      await Talsec.instance.start(
        TalsecConfig(
          watcherMail: _mail,
          isProd: kReleaseMode,
          androidConfig: AndroidConfig(
            packageName: _pkg,
            signingCertHashes: [_debugHash, ..._extraHashes.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty)],
          ),
        ),
      );
    } catch (e, st) {
      AppLog.error('security.rasp.start_failed', error: e, stack: st);
    }
  }

  static final _seen = <String>{};

  static void _note(String threat) {
    if (_seen.add(threat)) AppLog.warn('security.threat', fields: {'threat': threat, 'action': 'log'});
  }

  static void _block(String threat) {
    if (_seen.add(threat)) AppLog.error('security.threat', fields: {'threat': threat, 'action': 'block'});
    blocked.value = threat;
  }
}
