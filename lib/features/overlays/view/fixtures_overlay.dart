import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return BlocBuilder<MatchesCubit, MatchesState>(
      builder: (context, s) {
        final gw = s.matches.isNotEmpty ? s.matches.first.week : null;
        final next = _earliest(s.matches);
        return OverlayShell(
          title: 'الماتشات',
          subtitle: gw != null ? 'FIXTURES · GAMEWEEK ${gw.toString().padLeft(2, '0')}' : 'FIXTURES',
          onBack: nav.back,
          trailing: gw != null ? Text('GW$gw', style: AppText.h(13, color: AppColors.white)) : null,
          children: [
            if (next != null) _deadline(next),
            if (s.isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              )
            else if (s.matches.isEmpty)
              _empty()
            else
              _live(s.matches),
          ],
        );
      },
    );
  }

  GameMatch? _earliest(List<GameMatch> matches) {
    if (matches.isEmpty) return null;
    var first = matches.first;
    for (final m in matches) {
      if (m.dateTime.isBefore(first.dateTime)) first = m;
    }
    return first;
  }

  Widget _deadline(GameMatch m) {
    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: Row(children: [
        const BlinkDot(color: AppColors.accent),
        const SizedBox(width: 8),
        Text('يقفل ${arabicWeekday(m.deadline)} ${arabicTime(m.deadline)} · اختر قبلها',
            style: AppText.h(11, color: AppColors.white)),
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
