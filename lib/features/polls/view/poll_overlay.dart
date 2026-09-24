import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../overlays/widgets/overlay_shell.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../cubit/poll_cubit.dart';
import '../data/models/poll.dart';
import '../data/polls_repository.dart';

/// عرض تصويت (نجم الجولة / تحدّي الجولة) — اليوزر يصوّت ويشوف النتايج.
class PollOverlay extends StatelessWidget {
  const PollOverlay({super.key, required this.kind, required this.title, required this.subtitle});

  final String kind;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => PollCubit(c.read<PollsRepository>(), kind, userId)..load(),
      child: _View(title: title, subtitle: subtitle),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return BlocBuilder<PollCubit, PollState>(
      builder: (context, s) {
        return OverlayShell(
          title: title,
          subtitle: subtitle,
          onBack: nav.back,
          children: s.isLoading
              ? [const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.accent)))]
              : (s.view == null ? _empty() : _poll(context, s.view!)),
        );
      },
    );
  }

  List<Widget> _empty() => [
        Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text('المدير لسه محطّش تصويت دلوقتي',
                textAlign: TextAlign.center, style: AppText.body(13, color: AppColors.neutral600)),
          ),
        ),
      ];

  List<Widget> _poll(BuildContext context, PollView v) {
    final total = v.totalVotes;
    final closed = !v.poll.active;
    final winner = v.winner;
    return [
      if (closed)
        Container(
          width: double.infinity,
          color: AppColors.accent,
          padding: const EdgeInsets.all(14),
          child: Text(
            winner == null ? 'التصويت انتهى 🏁' : 'التصويت انتهى 🏆 الفايز: ${winner.label}',
            style: AppText.h(15, color: AppColors.white),
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Text(v.poll.question, style: AppText.h(18)),
      ),
      for (final o in v.options) _optionRow(context, v, o, total),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
        child: Text(
          closed || v.iVoted ? 'إجمالي الأصوات: $total' : 'دوس على اختيارك عشان تصوّت',
          style: AppText.body(11, color: AppColors.neutral600),
        ),
      ),
    ];
  }

  Widget _optionRow(BuildContext context, PollView v, PollOption o, int total) {
    final pct = total == 0 ? 0.0 : o.votes / total;
    final showResults = v.iVoted || !v.poll.active;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: v.poll.active ? () => context.read<PollCubit>().vote(o.id) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        decoration: BoxDecoration(border: Border.all(color: o.mine ? AppColors.accent : AppColors.black, width: 2)),
        child: Stack(children: [
          // شريط النسبة
          if (showResults)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: pct.clamp(0, 1),
                child: Container(color: AppColors.accent100),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              if (o.mine) ...[
                const Icon(Icons.check_circle, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
              ],
              Expanded(child: Text(o.label, style: AppText.h(14))),
              if (showResults) Text('${(pct * 100).round()}% · ${o.votes}', style: AppText.h(12)),
            ]),
          ),
        ]),
      ),
    );
  }
}
