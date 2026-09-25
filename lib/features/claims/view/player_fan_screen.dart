import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/share/share_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/data/models/player.dart';
import '../../week/data/week_window.dart';
import '../data/claims_repository.dart';
import '../data/models/fan_stats.dart';

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
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                final s = snap.data!;
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    RepaintBoundary(key: _cardKey, child: _card(s)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () => ShareCard.share(
                          _cardKey,
                          'أنا ${p.name} في الخماسي — ${s.owners} اختاروني و${s.captains} خلّوني كابتن الجولة دي 🔥 نزّل الأبلكيشن واختارني!',
                        ),
                        child: Container(
                          color: AppColors.accent,
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

  Widget _card(FanStats s) => Container(
    color: AppColors.black,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: 70, verified: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: AppText.h(22, color: AppColors.white)),
                  Text('${p.team} · ${p.positionAr}', style: AppText.body(11, color: AppColors.neutral400)),
                ],
              ),
            ),
            Text('5', style: AppText.h(26, color: AppColors.accent)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _stat('${s.owners}', 'اختاروك'),
            _stat('${s.captains}', 'خلّوك كابتن'),
            _stat('${s.ownership.toStringAsFixed(0)}%', 'الامتلاك'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _stat(s.posTotal == 0 ? '—' : '#${s.posRank}', 'في ${p.positionAr} من ${s.posTotal}'),
            _stat('${s.pointsForUsers}', 'نقطة جبتها لليوزرز'),
            _stat('${s.managers}', 'عملوا تشكيلة'),
          ],
        ),
      ],
    ),
  );

  Widget _stat(String v, String k) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(v, style: AppText.h(24, color: AppColors.accent400)),
        Text(k, style: AppText.body(10, color: AppColors.white.withValues(alpha: 0.7))),
      ],
    ),
  );
}
