import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../matches/data/models/game_match.dart';
import '../data/models/challenge_extras.dart';

part 'challenge_sections_extra.dart';

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
