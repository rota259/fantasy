import 'supabase_config.dart';
import 'supabase_service.dart';

/// احتياطي لمهمة السيرفر الدورية (fn_tick): لو pg_cron مش شغّال، الأبلكيشن بيناديها.
/// السيرفر نفسه بيمنع التكرار (مرة كل ٤ دقايق بالكتير)، واحنا بنناديها مرة كل ١٠ دقايق من الجهاز.
abstract final class ServerTick {
  ServerTick._();

  static DateTime? _last;

  static Future<void> run() async {
    if (!SupabaseConfig.isConfigured) return;
    final now = DateTime.now();
    if (_last != null && now.difference(_last!) < const Duration(minutes: 10)) return;
    _last = now;
    try {
      await SupabaseService.client.rpc('fn_tick', params: {'p_limit': 20});
    } catch (_) {}
  }
}
