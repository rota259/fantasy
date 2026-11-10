import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_navigator.dart';
import '../../../core/notifications/device_notify.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../notification_router.dart';

part 'push_banner_sections.dart';

/// شريط الإشعار والأبلكيشن مفتوح (النظام مبيعرضش إشعاراته وانت جوه الأبلكيشن):
/// كارت غامق بينزل من فوق بلون النوع وأيقونته — الضغط بيفتح صفحته، والسحب لفوق بيقفله، وبيختفي لوحده.
class PushBannerHost extends StatefulWidget {
  const PushBannerHost({super.key, required this.child});
  final Widget child;

  @override
  State<PushBannerHost> createState() => _PushBannerHostState();
}

class _PushBannerHostState extends State<PushBannerHost> {
  StreamSubscription<RemoteMessage>? _sub;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    try {
      _sub = FirebaseMessaging.onMessage.listen(_show);
    } catch (_) {} // منصّة من غير Firebase
  }

  void _show(RemoteMessage m) {
    final n = m.notification;
    final overlay = appNavigatorKey.currentState?.overlay;
    if (n == null || overlay == null || (n.title ?? '').isEmpty) return;
    _entry?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Banner(
        title: n.title!,
        body: n.body ?? '',
        kind: (m.data['kind'] ?? '').toString(),
        onClose: () {
          if (_entry == entry) _entry = null;
          entry.remove();
        },
        onTap: () {
          final ctx = appNavigatorKey.currentContext;
          if (ctx != null) {
            NotificationRouter.open(ctx, link: m.data['link']?.toString(), matchId: m.data['match_id']?.toString());
          }
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    DeviceNotify.show(n.title!, n.body ?? '', m.data); // ويفضل في شريط الإشعارات بعد ما الشريط ده يختفي
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// لون وأيقونة كل نوع (نفس تقسيمة الأصوات).
({Color color, IconData icon}) _look(String kind) => switch (kind) {
  'event' => (color: const Color(0xFFE5484D), icon: Icons.sports_soccer),
  'match' => (color: const Color(0xFF1FA85A), icon: Icons.sports),
  'lineup' => (color: const Color(0xFF3B9EFF), icon: Icons.groups_2_outlined),
  'badge' || 'challenge' || 'vote' => (color: const Color(0xFFE8B931), icon: Icons.emoji_events_outlined),
  'status' => (color: const Color(0xFFFF8A3D), icon: Icons.healing_outlined),
  _ => (color: const Color(0xFF1FA85A), icon: Icons.notifications_none),
};

class _Banner extends StatefulWidget {
  const _Banner({
    required this.title,
    required this.body,
    required this.kind,
    required this.onClose,
    required this.onTap,
  });
  final String title, body, kind;
  final VoidCallback onClose, onTap;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  static const _stay = Duration(seconds: 5);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 240),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(_stay, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildBody(context);
}
