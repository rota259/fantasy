import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../cubit/tournament_cubit.dart';
import '../data/models/tournament.dart';

/// شجرة خروج المغلوب: عمود لكل دور (ربع · نص · نهائي) — الفايز بيتنقل للعمود اللي بعده لوحده.
class TournamentBracketView extends StatelessWidget {
  const TournamentBracketView({super.key, required this.state});
  final TournamentState state;

  static String _name(int teams) => switch (teams) {
    2 => 'النهائي',
    4 => 'نص النهائي',
    8 => 'ربع النهائي',
    _ => 'دور الـ$teams',
  };

  @override
  Widget build(BuildContext context) {
    final b = state.bracket;
    if (b.isEmpty) {
      return Center(
        child: Text(
          state.tournament?.format == 'groups' ? 'الشجرة بتبدأ بعد المجموعات' : 'الشجرة بتتعمل مع القرعة',
          style: AppText.body(13, color: AppColors.neutral600),
        ),
      );
    }
    final first = b.where((s) => s.round == 1).length;
    final rounds = <int, List<BracketSlot>>{};
    for (final s in b) {
      rounds.putIfAbsent(s.round, () => []).add(s);
    }
    var size = first;
    final cols = <Widget>[];
    for (var r = 1; size >= 2; r++, size ~/= 2) {
      final slots = {for (final s in rounds[r] ?? const <BracketSlot>[]) s.slot: s};
      cols.add(
        FadeSlideIn(
          index: r,
          child: SizedBox(
            width: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(_name(size), style: AppText.kicker(color: AppColors.accent, size: 11)),
                const SizedBox(height: 8),
                for (var k = 1; k <= size; k += 2) _pair(slots[k]?.team, slots[k + 1]?.team, r == 1),
              ],
            ),
          ),
        ),
      );
    }
    final champ = state.tournament?.champion;
    cols.add(
      SizedBox(
        width: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏆', style: AppText.h(40)),
            Text(
              champ ?? '؟',
              textAlign: TextAlign.center,
              style: AppText.h(15, color: const Color(0xFFB8860B)),
            ),
          ],
        ),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols),
    );
  }

  Widget _pair(String? a, String? b, bool firstRound) => Container(
    margin: const EdgeInsets.only(bottom: 14, left: 8),
    decoration: AppDecor.tile,
    child: Column(
      children: [
        _team(a ?? '—'),
        Divider(height: 1, color: AppColors.divider),
        _team(b ?? (firstRound ? 'راحة' : '—')),
      ],
    ),
  );

  Widget _team(String name) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.h(12, color: name == state.tournament?.champion ? AppColors.accent : AppColors.ink),
          ),
        ),
      ],
    ),
  );
}
