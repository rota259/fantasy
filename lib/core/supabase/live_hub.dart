import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_service.dart';

/// اتصال لايف واحد للأبلكيشن كله (Broadcast من السيرفر — قسم 24 في migrate_all.sql).
///
/// السيرفر بيبعت إشارة صغيرة `{kind}` لما حاجة تتغيّر: للمنطقة (`zone:ID`)، أو للكل (`all`)، أو ليوزر (`user:ID`).
/// الأنواع: `events` · `matches` · `polls` · `notify`. الشاشات بتسمع للنوع اللي يهمها وبتحمّل بنفسها،
/// وكل جهاز بيستنى وقت عشوائي صغير قبل التحميل عشان الأجهزة كلها متضربش السيرفر في نفس الثانية.
abstract final class LiveHub {
  LiveHub._();

  static final _kinds = StreamController<String>.broadcast();
  static final _channels = <RealtimeChannel>[];
  static final _rand = Random();
  static String? _key;

  /// بعد الدخول (أو تغيير المنطقة): بيفتح قنوات اليوزر مرة واحدة.
  static void connect({required String userId, int? zoneId}) {
    if (!SupabaseConfig.isConfigured) return;
    final key = '$userId:$zoneId';
    if (key == _key) return;
    disconnect();
    _key = key;
    final client = SupabaseService.client;
    for (final topic in ['all', 'user:$userId', if (zoneId != null) 'zone:$zoneId']) {
      _channels.add(client.channel(topic).onBroadcast(event: 'change', callback: _onMessage).subscribe());
    }
  }

  /// الخروج: نقفل القنوات.
  static void disconnect() {
    if (_channels.isEmpty) return;
    final client = SupabaseService.client;
    for (final c in _channels) {
      client.removeChannel(c);
    }
    _channels.clear();
    _key = null;
  }

  static void _onMessage(Map<String, dynamic> message) {
    final payload = message['payload'];
    final kind = (payload is Map ? payload['kind'] : null) ?? message['kind'];
    if (kind is String) _kinds.add(kind);
  }

  /// بيسمع لنوع تغيير. الإشارات اللي بتيجي ورا بعض بتتجمّع في نداء واحد بعد [debounce] + وقت عشوائي لحد [jitter].
  static StreamSubscription<void> on(
    String kind,
    void Function() onChange, {
    Duration debounce = const Duration(seconds: 1),
    Duration jitter = const Duration(seconds: 3),
  }) {
    Timer? timer;
    late final StreamSubscription<String> inner;
    final out = StreamController<void>(
      onCancel: () {
        timer?.cancel();
        return inner.cancel();
      },
    );
    inner = _kinds.stream.where((k) => k == kind).listen((_) {
      timer?.cancel();
      timer = Timer(debounce + Duration(milliseconds: _rand.nextInt(jitter.inMilliseconds + 1)), onChange);
    });
    return out.stream.listen(null);
  }
}
