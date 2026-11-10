import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase_config.dart';
import '../supabase/supabase_service.dart';
import 'log_entry.dart';

/// بيبعت السجلات المهمة للسجل المركزي (جدول app_logs عن طريق log_events) على دفعات.
///   • بيتبعت: info وأعلى (debug عمره ما يتبعت — ده أغلب الحجم ومالوش لازمة في السيرفر)
///   • كل ١٥ ثانية أو أول ما يتجمّع ١٠ · والأخطاء بتتبعت بعد ثانيتين
///   • النت قاطع؟ بتفضل في الطابور (آخره ١٠٠)، وآخر ٣٠ بيتحفظوا على الجهاز ويتبعتوا المرة الجاية
///     — عشان لو الأبلكيشن وقع، الخطأ اللي وقّعه ميضيعش.
class LogShipper {
  LogShipper._();
  static final LogShipper instance = LogShipper._();

  static const _prefsKey = 'pending_logs';
  static const _maxQueue = 100, _batch = 20;

  final List<Map<String, Object?>> _queue = [];
  Timer? _timer;
  bool _sending = false;

  /// بيتنادى مرة في أول الأبلكيشن: يرجّع اللي متبعتش المرة اللي فاتت ويبدأ العدّاد.
  Future<void> start() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        _queue.insertAll(0, (jsonDecode(saved) as List).map((e) => Map<String, Object?>.from(e as Map)));
        await prefs.remove(_prefsKey);
      }
    } catch (_) {}
    _timer ??= Timer.periodic(const Duration(seconds: 15), (_) => flush());
  }

  void add(LogEntry entry) {
    if (entry.level == LogLevel.debug) return;
    _queue.add(entry.toJson());
    if (_queue.length > _maxQueue) _queue.removeRange(0, _queue.length - _maxQueue);
    if (entry.level.index >= LogLevel.error.index) {
      _persist();
      Timer(const Duration(seconds: 2), flush);
    } else if (_queue.length >= 10) {
      flush();
    }
  }

  /// ابعت اللي في الطابور (بيتنادى كمان لما الأبلكيشن يروح الخلفية).
  Future<void> flush() async {
    if (_sending || _queue.isEmpty || !SupabaseConfig.isConfigured) return;
    _sending = true;
    try {
      while (_queue.isNotEmpty) {
        final batch = _queue.take(_batch).toList();
        await SupabaseService.client.rpc('log_events', params: {'p_events': batch});
        _queue.removeRange(0, batch.length);
      }
      await _persist();
    } catch (_) {
      await _persist(); // هيتبعتوا المحاولة الجاية
    } finally {
      _sending = false;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_queue.isEmpty) {
        await prefs.remove(_prefsKey);
      } else {
        final last = _queue.length > 30 ? _queue.sublist(_queue.length - 30) : _queue;
        await prefs.setString(_prefsKey, jsonEncode(last));
      }
    } catch (_) {}
  }
}
