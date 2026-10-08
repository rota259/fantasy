import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../cubit/tournament_cubit.dart';
import '../data/models/tournament.dart';

/// الترتيب (الدوري أو كل مجموعة): لعب · فاز · تعادل · خسر · فارق · نقط — والأوائل المتأهلين بالأخضر.
/// المنظّم: لما المجموعات تخلص يبدأ خروج المغلوب.
class TournamentTableTab extends StatelessWidget {
  const TournamentTableTab({super.key, required this.state, required this.runs});
  final TournamentState state;
  final bool runs;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<TournamentRow>>{};
    for (final r in state.table) {
      groups.putIfAbsent(r.group == null ? 'الترتيب' : 'مجموعة ${r.group}', () => []).add(r);
    }
    final isGroups = state.tournament?.format == 'groups';
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        if (runs && state.groupsDone)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: FilledButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final err = await context.read<TournamentCubit>().startKnockout();
                messenger.showSnackBar(SnackBar(content: Text(err ?? 'المتأهلين اتعرفوا — شوف الشجرة ⚔️')));
              },
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('⚔️ ابدأ خروج المغلوب'),
            ),
          ),
        for (final e in groups.entries)
          Container(
            margin: AppDecor.tileMargin,
            padding: const EdgeInsets.all(12),
            decoration: AppDecor.tile,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(e.key, style: AppText.h(14, color: AppColors.accent)),
                    ),
                    for (final h in ['لعب', 'ف', 'ت', 'خ', '±', 'نقط']) _cell(h, header: true),
                  ],
                ),
                const Divider(),
                for (final (i, r) in e.value.indexed)
                  FadeSlideIn(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text('${i + 1}', style: AppText.h(12, color: AppColors.neutral500)),
                          ),
                          Expanded(
                            child: Text(
                              r.team,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.h(13, color: isGroups && i < 2 ? AppColors.accent : AppColors.ink),
                            ),
                          ),
                          _cell('${r.played}'),
                          _cell('${r.won}'),
                          _cell('${r.drawn}'),
                          _cell('${r.lost}'),
                          _cell(r.gd > 0 ? '+${r.gd}' : '${r.gd}'),
                          _cell('${r.pts}', bold: true),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(String v, {bool header = false, bool bold = false}) => SizedBox(
    width: 30,
    child: Text(
      v,
      textAlign: TextAlign.center,
      style: header ? AppText.body(10, color: AppColors.neutral600) : AppText.h(bold ? 14 : 12),
    ),
  );
}
