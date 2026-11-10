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

part 'tournament_awards_tab_sections.dart';

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
}
