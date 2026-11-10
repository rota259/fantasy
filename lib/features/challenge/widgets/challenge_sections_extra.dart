part of 'challenge_sections.dart';

/// الأقسام الجديدة (مين فيهم؟ · ٣ أسئلة · المعكوس) لتحدّي واحد.
class ChallengeSections extends StatelessWidget {
  const ChallengeSections({
    super.key,
    required this.match,
    required this.extras,
    required this.answers,
    required this.open,
    required this.onChanged,
  });

  final GameMatch match;
  final ChallengeExtras extras;
  final ChallengeAnswers answers;
  final bool open;
  final ValueChanged<ChallengeAnswers> onChanged;

  String _names(List<String> ids) =>
      ids.isEmpty ? '—' : [for (final id in ids) extras.player(id)?.name ?? '؟'].join(' · ');

  @override
  Widget build(BuildContext context) {
    final x = extras;
    final done = match.isFinished && x.result != null;
    int? pts(String mode) => done ? (x.points[mode] ?? 0) : null;
    final a = x.player(x.duelA), b = x.player(x.duelB);
    return Column(
      children: [
        if (x.has(ChallengeMode.duel) && a != null && b != null)
          ChallengeSection(
            mode: ChallengeMode.duel,
            points: pts(ChallengeMode.duel),
            note: done ? 'الأعلى نقط: ${_names(x.resultIds('duel_winners'))}' : null,
            child: ChoiceChips<String>(
              options: [(a.id, '${a.name} · ${a.team}'), (b.id, '${b.name} · ${b.team}')],
              value: answers.duel,
              correct: done ? x.resultIds('duel_winners') : const [],
              onChanged: open ? (v) => onChanged(answers.copyWith(duel: v)) : null,
            ),
          ),
        if (x.has(ChallengeMode.quiz))
          ChallengeSection(
            mode: ChallengeMode.quiz,
            points: pts(ChallengeMode.quiz),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('١. مين يكسب؟', style: AppText.h(12)),
                const SizedBox(height: 6),
                ChoiceChips<String>(
                  options: [('a', match.teamA), ('draw', 'تعادل'), ('b', match.teamB)],
                  value: answers.winner,
                  correct: done ? [x.result!['winner'].toString()] : const [],
                  onChanged: open ? (v) => onChanged(answers.copyWith(winner: v)) : null,
                ),
                const SizedBox(height: 12),
                Text('٢. مجموع الأهداف؟', style: AppText.h(12)),
                const SizedBox(height: 6),
                ChoiceChips<bool>(
                  options: const [(true, 'أكتر من ٦'), (false, '٦ أو أقل')],
                  value: answers.over,
                  correct: done ? [x.result!['over'] == true] : const [],
                  onChanged: open ? (v) => onChanged(answers.copyWith(over: v)) : null,
                ),
                const SizedBox(height: 12),
                Text(
                  '٣. مين يسجّل الأول؟${done ? ' — ${_names([if (x.result!['first_scorer'] != null) x.result!['first_scorer'].toString()])}' : ''}',
                  style: AppText.h(12),
                ),
                const SizedBox(height: 6),
                PlayerDropdown(
                  players: x.players,
                  value: answers.first,
                  hint: 'اختار اللاعب',
                  onChanged: open ? (v) => onChanged(answers.copyWith(first: v)) : null,
                ),
              ],
            ),
          ),
        if (x.has(ChallengeMode.lowest))
          ChallengeSection(
            mode: ChallengeMode.lowest,
            points: pts(ChallengeMode.lowest),
            note: done ? 'الأقل نقط: ${_names(x.resultIds('lowest'))}' : null,
            child: PlayerDropdown(
              players: x.players,
              value: answers.lowest,
              hint: 'مين هيبقى أقل واحد؟ (من الأساسيين)',
              onChanged: open ? (v) => onChanged(answers.copyWith(lowest: v)) : null,
            ),
          ),
      ],
    );
  }
}
