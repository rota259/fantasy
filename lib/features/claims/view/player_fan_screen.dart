import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/share/share_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/data/models/player.dart';
import '../../week/data/week_window.dart';
import '../data/claims_repository.dart';
import '../data/models/fan_stats.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../../core/share/story_frame.dart';

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
                    RepaintBoundary(key: _cardKey, child: _card(s)),
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

  /// كارت story للاعب الحقيقي: «اختارني N واحد كابتن 🔥» + أرقامه — جاهز للستوري.
  Widget _card(FanStats s) {
    final refCode = context.read<AuthCubit>().state.user?.refCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: StoryFrame(
        kicker: _window.label,
        refCode: refCode,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: 110, verified: true),
            const SizedBox(height: 10),
            Text(p.name, style: AppText.h(26, color: AppColors.white)),
            Text('${p.team} · ${p.positionAr}', style: AppText.body(12, color: AppColors.neutral400)),
            const SizedBox(height: 18),
            Text(
              s.captains > 0 ? 'اختارني ${s.captains} واحد كابتن 🔥' : 'اختارني ${s.owners} واحد في تشكيلته ⚽',
              textAlign: TextAlign.center,
              style: AppText.h(24, color: const Color(0xFFF2C14E)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _stat('${s.owners}', 'اختاروني'),
                _stat('${s.ownership.toStringAsFixed(0)}%', 'الامتلاك'),
                _stat('${s.pointsForUsers}', 'نقطة جبتها لهم'),
              ],
            ),
            if (s.posTotal > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '#${s.posRank} بين ${p.position == 'GK' ? 'الحراس' : 'اللاعيبة'} من ${s.posTotal}',
                  style: AppText.h(14, color: AppColors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String v, String k) => Expanded(
    child: Column(
      children: [
        Text(v, style: AppText.h(24, color: AppColors.accent400)),
        Text(k, style: AppText.body(10, color: AppColors.white.withValues(alpha: 0.7))),
      ],
    ),
  );
}
