import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/badges_repository.dart';
import '../data/models/user_badge.dart';
import '../view/badges_screen.dart';
import 'badge_tile.dart';

/// في البروفايل: آخر الشارات اللي اتاخدت + "كل الإنجازات ›". بتتحدّث لما شارة جديدة تتاخد.
class BadgesPreview extends StatefulWidget {
  const BadgesPreview({super.key, required this.userId, required this.userName});

  final String userId;
  final String userName;

  @override
  State<BadgesPreview> createState() => _BadgesPreviewState();
}

class _BadgesPreviewState extends State<BadgesPreview> {
  late Future<List<UserBadge>> _future = _load();
  StreamSubscription<void>? _sub;

  Future<List<UserBadge>> _load() => context.read<BadgesRepository>().forUser(widget.userId);

  @override
  void initState() {
    super.initState();
    _sub = liveTable(
      'user_badges',
      () {
        if (mounted) {
          setState(() {
            _future = _load();
          });
        }
      },
      eqColumn: 'user_id',
      eqValue: widget.userId,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserBadge>>(
      future: _future,
      builder: (context, snap) {
        final earned = (snap.data ?? const <UserBadge>[]).where((b) => b.earned && b.def != null).toList()
          ..sort((a, b) => (b.earnedAt ?? DateTime(0)).compareTo(a.earnedAt ?? DateTime(0)));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BadgesScreen(userId: widget.userId, userName: widget.userName),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('إنجازاتي · BADGES', style: AppText.kicker())),
                    Text('الكل ›', style: AppText.h(12, color: AppColors.accent)),
                  ],
                ),
                const SizedBox(height: 10),
                if (earned.isEmpty)
                  Text(
                    'لسه ماخدتش شارات — اعمل تشكيلتك كل جولة وهتبدأ تاخد 🔥',
                    style: AppText.body(12, color: AppColors.neutral600),
                  )
                else
                  Row(
                    children: [
                      for (final b in earned.take(5))
                        Expanded(
                          child: BadgeTile(def: b.def!, tier: b.tier, size: 46),
                        ),
                      for (var i = earned.length; i < 5; i++) const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
