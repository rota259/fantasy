import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/share/story_frame.dart';
import '../../../core/share/story_share_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../data/leagues_repository.dart';
import '../data/models/zone_standing.dart';

/// دوري المناطق: بدر ضد الشروق ضد التجمع — مجموع نقط ناس كل منطقة. منطقتك مميّزة، وتقدر تشيّر ترتيبها.
class ZoneLeagueScreen extends StatefulWidget {
  const ZoneLeagueScreen({super.key});

  @override
  State<ZoneLeagueScreen> createState() => _ZoneLeagueScreenState();
}

class _ZoneLeagueScreenState extends State<ZoneLeagueScreen> {
  late final Future<List<ZoneStanding>> _future = context.read<LeaguesRepository>().zoneStandings();

  void _share(ZoneStanding z) {
    final ref = context.read<AuthCubit>().state.user?.refCode;
    showStoryShare(
      context,
      card: StoryFrame(
        kicker: 'دوري المناطق',
        refCode: ref,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('منطقتي', style: AppText.h(16, color: Colors.white70)),
            Text(
              z.label,
              textAlign: TextAlign.center,
              style: AppText.h(26, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text('#${z.rank}', style: AppText.h(90, color: const Color(0xFFF2C14E), height: 1)),
            Text('${z.total} نقطة · ${z.users} لاعب', style: AppText.h(14, color: Colors.white)),
            const SizedBox(height: 16),
            Text('تعالى العب معانا ونطلّع منطقتنا الأولى 💪', style: AppText.body(13, color: Colors.white70)),
          ],
        ),
      ),
      text:
          'منطقتي ${z.label} ترتيبها #${z.rank} في دوري المناطق بالخماسي ⚽ تعالى العب وطلّعنا الأولى'
          '${ref == null ? '' : ' — كودي: $ref'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'دوري المناطق', subtitle: 'ZONES LEAGUE', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<ZoneStanding>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const SkeletonList();
                final list = snap.data!;
                final mine = list.where((z) => z.mine).firstOrNull;
                return ListView(
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'كل منطقة = مجموع نقط ناسها في الفانتازي. هات صحابك وجيرانك وطلّع منطقتك الأولى 💪',
                        style: AppText.body(12, color: AppColors.neutral700),
                      ),
                    ),
                    if (mine != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: FilledButton.icon(
                          onPressed: () => _share(mine),
                          icon: const Icon(Icons.ios_share),
                          label: Text('شيّر ترتيب ${mine.label.split(' · ').first} (#${mine.rank})'),
                        ),
                      ),
                    for (final (i, z) in list.indexed) FadeSlideIn(index: i, child: _row(z)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ZoneStanding z) {
    final medal = switch (z.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${z.rank}',
    };
    return Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: AppDecor.tile.copyWith(
        color: z.mine ? AppColors.accent100 : AppColors.card,
        border: z.mine ? Border.all(color: AppColors.accent300) : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: Text(medal, style: AppText.h(z.rank <= 3 ? 20 : 15))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${z.label}${z.mine ? ' · منطقتك' : ''}', style: AppText.h(14)),
                Text(
                  '${z.users} لاعب · متوسط ${z.avg.toStringAsFixed(1)}',
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          CountUp(
            value: z.total,
            style: AppText.h(20, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
