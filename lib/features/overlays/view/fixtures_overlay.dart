import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/blink_dot.dart';
import '../../../core/widgets/fdr_chip.dart';
import '../../matches/cubit/matches_cubit.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/overlay_shell.dart';

class FixturesOverlay extends StatelessWidget {
  const FixturesOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => MatchesCubit(c.read<MatchesRepository>())..load(),
      child: const _FixturesView(),
    );
  }
}

class _FixturesView extends StatelessWidget {
  const _FixturesView();

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return OverlayShell(
      title: 'الماتشات',
      subtitle: 'FIXTURES · GAMEWEEK 07',
      onBack: nav.back,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('‹  ', style: AppText.h(18, color: AppColors.white)),
        Text('GW7', style: AppText.h(13, color: AppColors.white)),
        Text('  ›', style: AppText.h(18, color: AppColors.white)),
      ]),
      children: [
        _deadline(),
        BlocBuilder<MatchesCubit, MatchesState>(
          builder: (context, s) {
            if (s.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              );
            }
            if (SupabaseConfig.isConfigured) {
              return s.hasData ? _live(s.matches) : _empty();
            }
            return _mock();
          },
        ),
      ],
    );
  }

  Widget _deadline() {
    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: Row(children: [
        const BlinkDot(color: AppColors.accent),
        const SizedBox(width: 8),
        Text('يقفل الخميس 8:00م · اختر قبلها', style: AppText.h(11, color: AppColors.white)),
      ]),
    );
  }

  Widget _live(List<GameMatch> matches) {
    final groups = <String, List<GameMatch>>{};
    for (final m in matches) {
      groups.putIfAbsent(arabicWeekday(m.dateTime), () => []).add(m);
    }
    return Column(
      children: [
        for (final entry in groups.entries) ...[
          _dayHeader(entry.key),
          for (final m in entry.value) _row(m.fdr, m.teamA, m.teamB, arabicTime(m.dateTime)),
        ],
        _legend(),
      ],
    );
  }

  Widget _mock() {
    return Column(children: [
      _dayHeader('الخميس · صعوبة اللاعبين (FDR)'),
      _row(2, 'التجمع', 'أكتوبر', '9:00م'),
      _row(3, 'المهندسين', 'الرحاب', '9:00م'),
      _row(5, 'المعادي', 'مدينة نصر', '10:30م'),
      _dayHeader('الجمعة'),
      _row(2, 'أكتوبر', 'الشيخ زايد', '7:00م'),
      _row(4, 'الرحاب', 'الزمالك سبورت', '9:00م'),
      _legend(),
    ]);
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Text('مفيش ماتشات قادمة', style: AppText.body(13, color: AppColors.neutral600)),
      ),
    );
  }

  Widget _dayHeader(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Text(t, style: AppText.kicker()),
      );

  Widget _row(int fdr, String a, String b, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        FdrChip(fdr),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$a ', style: AppText.h(13)),
            TextSpan(text: 'ضد', style: AppText.body(13, color: AppColors.neutral700)),
            TextSpan(text: ' $b', style: AppText.h(13)),
          ])),
        ),
        Text(time, style: AppText.h(12, color: AppColors.neutral600)),
      ]),
    );
  }

  Widget _legend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(children: [
        Text('FDR: ', style: AppText.body(10, color: AppColors.neutral700, weight: FontWeight.w600)),
        const FdrChip(2, size: 20),
        Text(' سهل   ', style: AppText.body(10, color: AppColors.neutral700)),
        const FdrChip(5, size: 20),
        Text(' صعب', style: AppText.body(10, color: AppColors.neutral700)),
      ]),
    );
  }
}
