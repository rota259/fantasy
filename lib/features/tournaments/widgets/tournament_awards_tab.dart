import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/share/story_frame.dart';
import '../../../core/share/story_share_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/confetti.dart';
import '../../../core/widgets/fx/effects.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/tournament_cubit.dart';
import '../data/models/tournament.dart';

/// الجوايز: البطل (كاس بيلف + confetti + كارت للشير) · الهداف · أحسن حارس · أحسن لاعب —
/// وتوقّع البطل (+١٠ لو صح) لحد أول ماتش.
class TournamentAwardsTab extends StatelessWidget {
  const TournamentAwardsTab({super.key, required this.state});
  final TournamentState state;

  @override
  Widget build(BuildContext context) {
    final t = state.tournament!;
    return Stack(
      children: [
        if (t.isFinished) const Positioned.fill(child: ConfettiBurst(count: 80)),
        ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            if (t.isFinished && t.champion != null) _champion(context, t),
            if (state.awards.isEmpty && !t.isFinished)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'الجوايز بتتحسب لوحدها مع الماتشات: الهداف · أحسن حارس · أحسن لاعب',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: AppColors.neutral600),
                ),
              ),
            for (final (i, a) in state.awards.indexed) FadeSlideIn(index: i, child: _award(a)),
            _predict(context),
          ],
        ),
      ],
    );
  }

  Widget _champion(BuildContext context, Tournament t) => Container(
    margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF7A5A12), Color(0xFFF2C14E)]),
      borderRadius: AppRadius.lg,
    ),
    child: Column(
      children: [
        CoinSpin(turns: 3, child: Text('🏆', style: AppText.h(54))),
        Text('بطل ${t.name}', style: AppText.h(14, color: Colors.black87)),
        Text(t.champion!, style: AppText.h(28, color: Colors.black)),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.black),
          onPressed: () => showStoryShare(
            context,
            card: StoryFrame(
              kicker: t.name,
              refCode: context.read<AuthCubit>().state.user?.refCode,
              colors: const [Color(0xFF7A5A12), Color(0xFF1E1606)],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏆', style: AppText.h(90)),
                  Text('البطل', style: AppText.h(18, color: Colors.white70)),
                  Text(
                    t.champion!,
                    textAlign: TextAlign.center,
                    style: AppText.h(34, color: const Color(0xFFF2C14E)),
                  ),
                  const SizedBox(height: 18),
                  for (final a in state.awards)
                    Text('${a.title}: ${a.name} (${a.value} ${a.unit})', style: AppText.h(13, color: Colors.white)),
                ],
              ),
            ),
            text: '🏆 ${t.champion} بطل ${t.name} — تابع بطولات منطقتك في الخماسي',
          ),
          icon: const Icon(Icons.ios_share),
          label: const Text('شيّر البطل'),
        ),
      ],
    ),
  );

  Widget _award(TournamentAward a) => Container(
    margin: AppDecor.tileMargin,
    padding: const EdgeInsets.all(14),
    decoration: AppDecor.tile,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title, style: AppText.kicker(color: AppColors.accent, size: 11)),
              Text(a.name, style: AppText.h(16)),
              Text(a.team, style: AppText.body(11, color: AppColors.neutral700)),
            ],
          ),
        ),
        Text('${a.value}', style: AppText.h(26, color: AppColors.accent)),
        Text(' ${a.unit}', style: AppText.body(11)),
      ],
    ),
  );

  /// توقّع البطل: الفرق بعدد اللي توقّعوا كل واحد · توقّعي مميّز.
  Widget _predict(BuildContext context) {
    final s = state;
    final total = s.picks.values.fold(0, (a, b) => a + b);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🔮 مين هياخد الكاس؟ (+١٠ لو صح)', style: AppText.h(15)),
          Text(
            s.predictOpen ? 'التوقّع مفتوح لحد أول ماتش' : 'التوقّع اتقفل',
            style: AppText.body(11, color: AppColors.neutral700),
          ),
          const SizedBox(height: 8),
          for (final team in s.approved)
            Pressable(
              onTap: !s.predictOpen
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final err = await context.read<TournamentCubit>().predict(team.team);
                      messenger.showSnackBar(SnackBar(content: Text(err ?? 'توقّعت ${team.team} 🔮')));
                    },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: s.myPick == team.team ? AppColors.accent100 : null,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: s.myPick == team.team ? AppColors.accent : AppColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(team.team, style: AppText.h(13))),
                    if (total > 0)
                      Text(
                        '${((s.picks[team.team] ?? 0) * 100 / total).round()}%',
                        style: AppText.h(12, color: AppColors.neutral700),
                      ),
                    if (s.myPick == team.team) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle, color: AppColors.accent, size: 18),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
