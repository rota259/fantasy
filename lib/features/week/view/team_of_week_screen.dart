import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../cubit/team_of_week_cubit.dart';
import '../data/models/week_player.dart';
import '../data/week_repository.dart';

const _order = [('GK', 'حارس المرمى'), ('DEF', 'الدفاع'), ('MID', 'الوسط'), ('FWD', 'الهجوم')];

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
      body: Column(
        children: [
          const StatusArea(),
          BlocBuilder<TeamOfWeekCubit, TeamOfWeekState>(
            builder: (context, s) {
              final cubit = context.read<TeamOfWeekCubit>();
              return Masthead(
                title: 'تشكيلة الأسبوع',
                subtitle: 'TEAM OF THE WEEK',
                onBack: () => Navigator.pop(context),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(onTap: () => cubit.setWeek(s.week - 1),
                      child: Text('‹  ', style: AppText.h(18, color: AppColors.white))),
                  Text('GW${s.week}', style: AppText.h(13, color: AppColors.white)),
                  GestureDetector(onTap: () => cubit.setWeek(s.week + 1),
                      child: Text('  ›', style: AppText.h(18, color: AppColors.white))),
                ]),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<TeamOfWeekCubit, TeamOfWeekState>(
              builder: (context, s) {
                if (s.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (s.players.isEmpty) {
                  return Center(child: Text('لسه مفيش نقاط في الجولة دي',
                      style: AppText.body(13, color: AppColors.neutral600)));
                }
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final pos in _order)
                      if (s.byPosition(pos.$1).isNotEmpty) ...[
                        _header(pos.$2),
                        for (final p in s.byPosition(pos.$1)) _row(p),
                      ],
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(t, style: AppText.h(15)),
      );

  Widget _row(WeekPlayer p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        InitialsTile(p.initials, background: AppColors.accent, color: AppColors.white),
        const SizedBox(width: 11),
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
}
