import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../overlays/widgets/overlay_shell.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../cubit/challenge_cubit.dart';
import '../data/challenge_repository.dart';
import '../data/models/prediction.dart';
import '../widgets/challenge_card.dart';

/// تحدّي الجولة: كل مدير في منطقتي بيختار ماتش من ماتشاته — توقّع، واللي يجيب فرق الأهداف صح ياخد +٥.
class ChallengeOverlay extends StatelessWidget {
  const ChallengeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => ChallengeCubit(c.read<ChallengeRepository>(), userId)..load(),
      child: BlocBuilder<ChallengeCubit, ChallengeState>(
        builder: (context, s) => OverlayShell(
          title: 'تحدّي الجولة',
          subtitle: 'PREDICT & WIN +${Prediction.bonus}',
          onBack: context.read<AppNavCubit>().back,
          children: s.loading
              ? [
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                  ),
                ]
              : s.items.isEmpty
              ? [_note('مفيش تحدّي في منطقتك دلوقتي — المديرين بينزّلوه قبل ماتشاتهم')]
              : [
                  for (final (i, it) in s.items.indexed)
                    FadeSlideIn(
                      index: i,
                      child: ChallengeCard(key: ValueKey(it.match.id), item: it),
                    ),
                  const SizedBox(height: 16),
                ],
        ),
      ),
    );
  }

  Widget _note(String t) => Padding(
    padding: const EdgeInsets.all(28),
    child: Center(
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: AppText.h(14, color: AppColors.neutral700),
      ),
    ),
  );
}
