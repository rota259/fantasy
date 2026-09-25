import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../polls/data/polls_repository.dart';
import '../cubit/team_of_week_cubit.dart';
import '../data/models/week_player.dart';
import '../data/week_repository.dart';
import '../widgets/totw_pitch.dart';
import '../widgets/totw_tie_section.dart';

/// تشكيلة الجولة: أعلى ٥ نقط على خماسي أزرق — مباشر لحد الجمعة ٤ الفجر، بعدها نهائي.
class TeamOfWeekScreen extends StatelessWidget {
  const TeamOfWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => TeamOfWeekCubit(c.read<WeekRepository>(), c.read<PollsRepository>(), userId)..load(),
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
          return Column(
            children: [
              const StatusArea(),
              Masthead(
                title: 'تشكيلة الجولة',
                subtitle: 'TEAM OF THE WEEK',
                onBack: () => Navigator.pop(context),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: cubit.previous,
                      child: Text('‹  ', style: AppText.h(20, color: AppColors.white)),
                    ),
                    GestureDetector(
                      onTap: s.isCurrent ? null : cubit.next,
                      child: Text(
                        '  ›',
                        style: AppText.h(20, color: s.isCurrent ? AppColors.neutral600 : AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.navy,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: isFinal ? AppColors.info : AppColors.danger,
                      child: Text(
                        isFinal ? 'النهائي ✓' : '● مباشر — بتتغيّر مع كل نقطة',
                        style: AppText.h(10, color: AppColors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.window.label, style: AppText.body(10, color: AppColors.neutral400)),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context, s)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, TeamOfWeekState s) {
    if (s.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.info));
    final team = s.team;
    if (team.sure.isEmpty && !team.hasTie) {
      return Center(
        child: Text('لسه مفيش نقاط في الجولة دي', style: AppText.body(13, color: AppColors.neutral600)),
      );
    }
    final cubit = context.read<TeamOfWeekCubit>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        TotwPitch(spots: s.spots, contested: s.contested),
        if (s.contested)
          TotwTieSection(
            tied: team.tied,
            slots: team.openSlots,
            poll: s.tie,
            onVote: (id) async {
              final messenger = ScaffoldMessenger.of(context);
              final err = await cubit.voteTie(id);
              if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
            },
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Text('ترتيب الجولة', style: AppText.h(15)),
        ),
        for (var i = 0; i < s.players.length && i < 15; i++) _row(i + 1, s.players[i]),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _row(int rank, WeekPlayer p) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 24,
          child: Text('$rank', style: AppText.h(13, color: AppColors.info)),
        ),
        PentagonAvatar(
          initials: p.initials,
          photoUrl: p.imageUrl,
          size: 34,
          background: AppColors.info,
          verified: p.verified,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: AppText.h(14)),
              Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
            ],
          ),
        ),
        Text('${p.points}', style: AppText.h(20)),
      ],
    ),
  );
}
