import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../../../core/widgets/status_bar.dart';
import '../cubit/team_of_week_cubit.dart';
import '../data/models/week_player.dart';
import '../data/week_repository.dart';

const _order = [('GK', 'حارس المرمى'), ('DEF', 'الدفاع'), ('MID', 'الوسط'), ('FWD', 'الهجوم')];

/// أماكن الخماسي: حارس تحت، دفاع شمال تحت، وسط شمال فوق، هجوم يمين فوق، الزيادة يمين تحت.
const _spots = [(50.0, 86.0), (16.0, 60.0), (29.0, 20.0), (71.0, 20.0), (84.0, 60.0)];

class TeamOfWeekScreen extends StatelessWidget {
  const TeamOfWeekScreen({super.key, required this.weekRepo});
  final WeekRepository weekRepo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TeamOfWeekCubit(weekRepo)..load(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<TeamOfWeekCubit, TeamOfWeekState>(
        builder: (context, s) {
          final cubit = context.read<TeamOfWeekCubit>();
          final isFinal = s.window.isFinal();
          return Column(children: [
            const StatusArea(),
            Masthead(
              title: 'تشكيلة الأسبوع',
              subtitle: 'TEAM OF THE WEEK',
              onBack: () => Navigator.pop(context),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(onTap: cubit.previous, child: Text('‹  ', style: AppText.h(20, color: AppColors.white))),
                GestureDetector(
                  onTap: s.isCurrent ? null : cubit.next,
                  child: Text('  ›', style: AppText.h(20, color: s.isCurrent ? AppColors.neutral600 : AppColors.white)),
                ),
              ]),
            ),
            Container(
              width: double.infinity,
              color: AppColors.black,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: isFinal ? AppColors.accent : AppColors.danger,
                  child: Text(isFinal ? 'النهائي ✓' : '● مباشر — بتتغيّر مع كل نقطة',
                      style: AppText.h(10, color: AppColors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(s.window.label, style: AppText.body(10, color: AppColors.neutral400))),
              ]),
            ),
            Expanded(child: _body(s)),
          ]);
        },
      ),
    );
  }

  Widget _body(TeamOfWeekState s) {
    if (s.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    if (s.players.isEmpty) {
      return Center(child: Text('لسه مفيش نقاط في الجولة دي', style: AppText.body(13, color: AppColors.neutral600)));
    }
    final lineup = s.lineup;
    return ListView(padding: EdgeInsets.zero, children: [
      PentagonPitch(height: 340, tokens: [
        for (var i = 0; i < 5; i++)
          if (lineup[i] != null)
            PitchToken(leftPct: _spots[i].$1, topPct: _spots[i].$2, child: _token(lineup[i]!)),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text('الترتيب في كل مركز', style: AppText.h(15)),
      ),
      for (final pos in _order)
        if (s.byPosition(pos.$1).isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(pos.$2, style: AppText.kicker(color: AppColors.accent)),
          ),
          for (final p in s.byPosition(pos.$1)) _row(p),
        ],
      const SizedBox(height: 16),
    ]);
  }

  Widget _token(WeekPlayer p) => SizedBox(
        width: 76,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 46, height: 46, alignment: Alignment.center,
            color: AppColors.accent,
            child: Text(p.initials, style: AppText.h(16, color: AppColors.white)),
          ),
          const SizedBox(height: 3),
          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(10, color: AppColors.white)),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            color: AppColors.white,
            child: Text('${p.points}', style: AppText.h(11, color: AppColors.black)),
          ),
        ]),
      );

  Widget _row(WeekPlayer p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: AppText.h(14)),
              Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
            ]),
          ),
          Text('${p.points}', style: AppText.h(20)),
        ]),
      );
}
