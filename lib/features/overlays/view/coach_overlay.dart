import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../coach/coach_engine.dart';
import '../../coach/cubit/coach_cubit.dart';
import '../../players/data/players_repository.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../squad/cubit/squad_cubit.dart';
import '../widgets/coach_recommendation.dart';
import '../widgets/overlay_shell.dart';

class CoachOverlay extends StatelessWidget {
  const CoachOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final squad = context.read<SquadCubit>().state;
    return BlocProvider(
      create: (c) =>
          CoachCubit(c.read<PlayersRepository>())..load(squad.players, squad.remaining),
      child: const _CoachView(),
    );
  }
}

class _CoachView extends StatelessWidget {
  const _CoachView();

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return BlocBuilder<CoachCubit, CoachState>(
      builder: (context, s) {
        final a = s.advice;
        return OverlayShell(
          title: 'مدرّب الذكاء',
          subtitle: 'AI COACH',
          onBack: nav.back,
          bottomBar: _askBar(),
          children: s.isLoading
              ? [const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.accent)))]
              : a == null
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'لسه مفيش توصيات — لازم يكون فيه لاعيبة واختيارات الأول',
                            textAlign: TextAlign.center,
                            style: AppText.body(13, color: AppColors.neutral600),
                          ),
                        ),
                      ),
                    ]
                  : [
                      _alert(a),
                      _header('توصية التحويل'),
                      CoachRecommendation(advice: a, onAct: () => _apply(context, a)),
                      _header('كابتن الجولة المقترح'),
                      _captainCard(a),
                      const SizedBox(height: 16),
                    ],
        );
      },
    );
  }

  void _apply(BuildContext context, CoachAdvice a) {
    final squad = context.read<SquadCubit>();
    squad.removePlayer(a.out.id);
    final err = squad.addPlayer(a.incoming);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'اتنفّذ: ${a.out.name} ← ${a.incoming.name}'),
      duration: const Duration(milliseconds: 1500),
    ));
    context.read<AppNavCubit>().back();
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
        child: Text(t, style: AppText.h(15)),
      );

  Widget _alert(CoachAdvice a) {
    final title = '${a.out.name} فورمته ضعيفة ⚠️';
    const body = 'أقل لاعب فورمة في تشكيلتك — يستحسن تبدّله.';
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      decoration: BoxDecoration(border: Border.all(color: AppColors.accent, width: 2)),
      child: IntrinsicHeight(
        child: Row(children: [
          Container(
            color: AppColors.accent,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.white),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(13)),
                  const SizedBox(height: 2),
                  Text(body, style: AppText.body(11, color: AppColors.neutral700)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _captainCard(CoachAdvice a) {
    final name = '${a.captain.name} — ${a.captain.team}';
    final ini = a.captain.initials;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 40, height: 40, alignment: Alignment.center,
            color: AppColors.accent,
            child: Text(ini, style: AppText.h(15, color: AppColors.white)),
          ),
          Positioned(
            top: -7, right: -7,
            child: Container(
              width: 16, height: 16, alignment: Alignment.center,
              color: AppColors.black,
              child: Text('C', style: AppText.h(9, color: AppColors.white)),
            ),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(14)),
              Text('أعلى فورمة في تشكيلتك',
                  style: AppText.body(11, color: AppColors.neutral700)),
            ],
          ),
        ),
        Text('×2', style: AppText.h(20, color: AppColors.accent)),
      ]),
    );
  }

  Widget _askBar() {
    return OverlayActionBar(
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(border: Border.all(color: AppColors.white.withValues(alpha: 0.35))),
            child: Text('اسأل المدرّب…',
                style: AppText.h(12, color: AppColors.white.withValues(alpha: 0.6))),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 38,
          height: 38,
          color: AppColors.accent,
          child: const Icon(Icons.arrow_forward, size: 18, color: AppColors.white),
        ),
      ]),
    );
  }
}
