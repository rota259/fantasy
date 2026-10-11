import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_navigator.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../notification_router.dart';

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

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted) await _c.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = _look(widget.kind);
    final slide = CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -1.4), end: Offset.zero).animate(slide),
        child: FadeTransition(
          opacity: _c,
          child: Dismissible(
            key: const ValueKey('push-banner'),
            direction: DismissDirection.up,
            onDismissed: (_) {
              _closing = true;
              _timer?.cancel();
              widget.onClose();
            },
            child: Material(
              color: Colors.transparent,
              child: Pressable(
                onTap: () {
                  widget.onTap();
                  _close();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xF2101814),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: look.color.withValues(alpha: 0.55), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: look.color.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 8)),
                      const BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 14, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: look.color.withValues(alpha: 0.18),
                                border: Border.all(color: look.color.withValues(alpha: 0.6)),
                              ),
                              child: Icon(look.icon, color: look.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.h(14, color: Colors.white),
                                  ),
                                  if (widget.body.isNotEmpty)
                                    Text(
                                      widget.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body(12, color: Colors.white.withValues(alpha: 0.78), height: 1.4),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_left, color: Colors.white.withValues(alpha: 0.5), size: 20),
                          ],
                        ),
                      ),
                      // شريط بيخلص مع وقت الإشعار
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1, end: 0),
                        duration: _stay,
                        builder: (_, v, _) => Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FractionallySizedBox(
                            widthFactor: v,
                            child: Container(height: 3, color: look.color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
