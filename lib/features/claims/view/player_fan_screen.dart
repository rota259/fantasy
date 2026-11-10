import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/share/share_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/jersey.dart';
import '../../../core/widgets/photo_card.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/data/models/player.dart';
import '../../week/data/week_window.dart';
import '../data/claims_repository.dart';
import '../data/models/fan_stats.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../../core/share/story_frame.dart';

part 'player_fan_screen_sections.dart';

/// "أنا كلاعب": اللاعب الحقيقي يشوف مين اختاره وخلّاه كابتن + يشيّر.
class PlayerFanScreen extends StatefulWidget {
  const PlayerFanScreen({super.key, required this.player});
  final Player player;

  @override
  State<PlayerFanScreen> createState() => _PlayerFanScreenState();
}

class _PlayerFanScreenState extends State<PlayerFanScreen> {
  final _cardKey = GlobalKey();
  final _window = WeekWindow.current();
  late final Future<FanStats> _future = context.read<ClaimsRepository>().fanStats(widget.player.id, _window);

  Player get p => widget.player;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'أنا كلاعب', subtitle: 'MY FANS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<FanStats>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const SkeletonList();
                final s = snap.data!;
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: RepaintBoundary(key: _cardKey, child: _card(s)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Pressable(
                        onTap: () => ShareCard.share(
                          _cardKey,
                          'أنا ${p.name} في الخماسي — ${s.owners} اختاروني و${s.captains} خلّوني كابتن الجولة دي 🔥 نزّل الأبلكيشن واختارني!',
                        ),
                        child: Container(
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                          padding: const EdgeInsets.all(13),
                          alignment: Alignment.center,
                          child: Text('شيّر على واتساب / ستوري', style: AppText.h(14, color: AppColors.white)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'الأرقام دي للجولة الحالية (${_window.label}) وبتتحدّث مع كل تشكيلة.',
                        style: AppText.body(11, color: AppColors.neutral600),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
