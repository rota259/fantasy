import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/sound_service.dart';
import '../../../core/supabase/live_hub.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/supabase_service.dart';
import '../data/models/app_notification.dart';

/// عدّاد الإشعارات المتشافتش (فوق الجرس) + تشغيل صوت مميّز لكل إشعار جديد.
/// الحالة = عدد الإشعارات الجديدة اللي اليوزر لسه ماشفهاش.
class NotificationsBadgeCubit extends Cubit<int> {
  NotificationsBadgeCubit(this._sound) : super(0) {
    _start();
  }

  final SoundService _sound;
  static const _key = 'notif_last_seen';

  StreamSubscription<void>? _sub;
  DateTime _lastSeen = DateTime.fromMillisecondsSinceEpoch(0);
  final Set<String> _known = {};
  bool _primed = false;

  Future<void> _start() async {
    if (!SupabaseConfig.isConfigured) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) {
      // أول مرة: اعتبر كل القديم متشاف عشان العدّاد يبدأ من صفر.
      _lastSeen = DateTime.now();
      await prefs.setString(_key, _lastSeen.toIso8601String());
    } else {
      _lastSeen = DateTime.tryParse(saved) ?? _lastSeen;
    }
    // أول تحميل، وبعدين مع كل إشارة "إشعار جديد" لجمهوري (من غير ما نسمع لجدول الإشعارات كله)
    await _fetch();
    _sub = LiveHub.on(
      'notify',
      _fetch,
      debounce: const Duration(milliseconds: 300),
      jitter: const Duration(seconds: 2),
    );
  }

  /// آخر ٥٠ بس (الجدول بيكبر مع الوقت) — السيرفر بيفلتر اللي يخصّني (RLS).
  Future<void> _fetch() async {
    try {
      final rows = await SupabaseService.table(
        'notifications',
      ).select('id, title, body, kind, created_at').order('created_at', ascending: false).limit(50);
      if (!isClosed) _onData(rows);
    } catch (_) {}
  }

  void _onData(List<Map<String, dynamic>> rows) {
    final items = rows.map(AppNotification.fromMap).toList();

    // تشغيل صوت لأي إشعار جديد وصل بعد ما الكيوبت اشتغل.
    if (_primed) {
      AppNotification? newest;
      for (final n in items) {
        if (!_known.contains(n.id)) {
          if (newest == null || n.createdAt.isAfter(newest.createdAt)) newest = n;
        }
      }
      if (newest != null) _sound.play(newest.kind);
    }
    _known
      ..clear()
      ..addAll(items.map((n) => n.id));
    _primed = true;

    final unread = items.where((n) => n.createdAt.isAfter(_lastSeen)).length;
    emit(unread);
  }

  /// اليوزر فتح الإشعارات → صفّر العدّاد.
  Future<void> markSeen() async {
    _lastSeen = DateTime.now();
    emit(0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _lastSeen.toIso8601String());
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _sound.dispose();
    return super.close();
  }
}
