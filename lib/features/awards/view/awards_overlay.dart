import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../matches/widgets/match_format.dart';
import '../../overlays/widgets/overlay_shell.dart';
import '../../polls/data/models/poll.dart';
import '../../polls/data/polls_repository.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../cubit/awards_cubit.dart';
import '../widgets/award_option_card.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// هدف وتصدّي الجولة (والموسم): اتفرّج على الفيديوهات وصوّت.
class AwardsOverlay extends StatelessWidget {
  const AwardsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(create: (c) => AwardsCubit(c.read<PollsRepository>(), userId)..load(), child: const _View());
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  String _kind = PollKind.goalWeek;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AwardsCubit, AwardsState>(
      builder: (context, s) {
        final tabs = s.tabs;
        if (!tabs.any((t) => t.$1 == _kind)) _kind = tabs.first.$1;
        return OverlayShell(
          title: 'هدف وتصدّي الجولة',
          subtitle: 'GOAL & SAVE OF THE WEEK',
          onBack: context.read<AppNavCubit>().back,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [for (final t in tabs) _tab(t.$1, t.$2)]),
            ),
            if (s.loading)
              Padding(padding: EdgeInsets.all(40), child: const SkeletonList())
            else if (s.polls[_kind] == null)
              _note('الإدارة لسه منزّلش المرشّحين')
            else
              ..._poll(context, s.polls[_kind]!),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _tab(String kind, String label) {
    final on = kind == _kind;
    return Pressable(
      onTap: () => setState(() => _kind = kind),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: on ? AppColors.black : null,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Text(label, style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
      ),
    );
  }

  List<Widget> _poll(BuildContext context, PollView v) {
    final open = v.poll.open;
    final winners = open ? const <PollOption>[] : v.winners;
    final closes = v.poll.closesAt;
    final cubit = context.read<AwardsCubit>();
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
        child: Text(v.poll.question, style: AppText.h(18)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: Text(
          open
              ? '${closes != null ? 'التصويت بيقفل ${arabicWeekday(closes)} ${arabicTime(closes)} · ' : ''}'
                    'دوس على الفيديو تتفرّج، وبعدين صوّت'
              : (winners.isEmpty ? 'التصويت خلص من غير أصوات' : '🏆 الفايز: ${winners.first.label}'),
          style: AppText.body(11, color: AppColors.neutral700),
        ),
      ),
      for (final o in v.options)
        AwardOptionCard(
          option: o,
          total: v.totalVotes,
          showResults: v.iVoted || !open,
          winner: winners.any((w) => w.id == o.id),
          onVote: open
              ? () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final err = await cubit.vote(_kind, o.id);
                  if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                }
              : null,
        ),
    ];
  }

  Widget _note(String t) => Padding(
    padding: const EdgeInsets.all(40),
    child: Center(
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: AppText.body(13, color: AppColors.neutral600),
      ),
    ),
  );
}
