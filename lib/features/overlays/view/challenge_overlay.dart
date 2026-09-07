import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../challenge/cubit/challenge_cubit.dart';
import '../../leagues/data/leagues_repository.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/challenge_vs_card.dart';
import '../widgets/overlay_shell.dart';

class ChallengeOverlay extends StatelessWidget {
  const ChallengeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthCubit>().state.user;
    return BlocProvider(
      create: (c) => ChallengeCubit(c.read<LeaguesRepository>())..load(me),
      child: const _ChallengeView(),
    );
  }
}

class _ChallengeView extends StatelessWidget {
  const _ChallengeView();

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return BlocBuilder<ChallengeCubit, ChallengeState>(
      builder: (context, s) {
        return OverlayShell(
          title: 'تحدّي الجولة',
          subtitle: 'HEAD TO HEAD',
          onBack: nav.back,
          bottomBar: _shareBar(nav),
          children: s.isLoading
              ? [const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.accent)))]
              : (s.result != null ? _live(s.result!) : _empty()),
        );
      },
    );
  }

  List<Widget> _live(ChallengeResult r) {
    return [
      ChallengeVsCard(
        meName: r.meName,
        meScore: '${r.mePoints}',
        oppName: r.oppName,
        oppScore: '${r.oppPoints}',
        meWins: r.meWins,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Text('المقارنة بإجمالي نقاطك ضد أقرب منافس في دوريك.',
            style: AppText.body(12, color: AppColors.neutral700)),
      ),
    ];
  }

  List<Widget> _empty() {
    return [
      Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text('انضم لدوري عشان تتحدّى أقرب منافس ليك',
              textAlign: TextAlign.center,
              style: AppText.body(13, color: AppColors.neutral600)),
        ),
      ),
    ];
  }

  Widget _shareBar(AppNavCubit nav) {
    return OverlayActionBar(
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: nav.back,
            child: Container(
              color: AppColors.accent,
              padding: const EdgeInsets.all(11),
              alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.share_outlined, size: 16, color: AppColors.white),
                const SizedBox(width: 7),
                Text('شارك واتساب', style: AppText.h(13, color: AppColors.white)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: nav.back,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(border: Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 2)),
            child: Text('نسخ', style: AppText.h(13, color: AppColors.white)),
          ),
        ),
      ]),
    );
  }

}
