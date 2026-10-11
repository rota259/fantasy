import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../matches/data/models/game_match.dart';
import '../data/models/challenge_extras.dart';

/// إطار قسم من التحدّي: العنوان + الشرح (أو النتيجة والنقط بعد الماتش) + المحتوى.
class ChallengeSection extends StatelessWidget {
  const ChallengeSection({super.key, required this.mode, required this.child, this.points, this.note});
  final String mode;
  final Widget child;
  final int? points; // بعد الماتش
  final String? note; // بدل الشرح

  @override
  Widget build(BuildContext context) {
    final won = (points ?? 0) > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: won ? AppColors.accent100 : null,
        border: Border.all(color: won ? AppColors.accent : AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(ChallengeMode.icon(mode), size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(child: Text(ChallengeMode.label(mode), style: AppText.h(14))),
              if (points != null)
                Text(won ? '+$points ✓' : '✗', style: AppText.h(14, color: won ? AppColors.accent : AppColors.danger)),
            ],
          ),
          Text(note ?? ChallengeMode.hint(mode), style: AppText.body(11, color: AppColors.neutral700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// اختيار من كذا حاجة (شرايح) — المختار أخضر، والصح بعد الماتش بعلامة.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({super.key, required this.options, required this.value, this.onChanged, this.correct = const []});
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final List<T> correct;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (v, label) in options)
        Pressable(
          onTap: onChanged == null ? null : () => onChanged!(v),
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: v == value ? AppColors.accent : null,
              border: Border.all(color: v == value ? AppColors.accent : AppColors.line, width: 1.4),
            ),
            child: Text(
              '$label${correct.contains(v) ? ' ✓' : ''}',
              style: AppText.h(12, color: v == value ? AppColors.white : AppColors.ink),
            ),
          ),
        ),
    ],
  );
}

/// قايمة لاعيبة الفريقين (أول هدّاف · أقل لاعب).
class PlayerDropdown extends StatelessWidget {
  const PlayerDropdown({super.key, required this.players, required this.value, required this.hint, this.onChanged});
  final List<ChallengePlayer> players;
  final String? value;
  final String hint;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: players.any((p) => p.id == value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(hintText: hint, isDense: true),
    items: [
      for (final p in players) DropdownMenuItem(value: p.id, child: Text('${p.name} · ${p.team}${p.gk ? ' 🧤' : ''}')),
    ],
    onChanged: onChanged,
  );
}

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
