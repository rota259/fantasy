import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../matches/widgets/match_format.dart';
import '../cubit/challenge_cubit.dart';
import '../data/models/prediction.dart';
import 'score_picker.dart';

/// كارت تحدّي واحد: توقّع النتيجة (المهم فرق الأهداف) قبل الماتش بساعة، وبعده صح ولا لأ.
class ChallengeCard extends StatefulWidget {
  const ChallengeCard({super.key, required this.item});

  final ChallengeItem item;

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard> {
  int? _a, _b; // المختار قبل الحفظ
  bool _saving = false;

  Future<void> _save() async {
    final m = widget.item.match;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final err = await context.read<ChallengeCubit>().predict(
      m,
      _a ?? widget.item.mine?.scoreA ?? 0,
      _b ?? widget.item.mine?.scoreB ?? 0,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'اتسجّل توقّعك ✓ — تقدر تغيّره لحد ${arabicTime(m.deadline)}'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final m = it.match;
    final a = _a ?? it.mine?.scoreA ?? 0;
    final b = _b ?? it.mine?.scoreB ?? 0;
    final open = !m.isLocked && !m.isFinished;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.black,
            padding: const EdgeInsets.all(14),
            child: Text(
              open
                  ? 'توقّع قبل ${arabicWeekday(m.deadline)} ${arabicTime(m.deadline)} — لو جبت فرق الأهداف صح +${Prediction.bonus} 🎯'
                  : (m.isFinished
                        ? 'الماتش خلص: ${m.teamA} ${m.scoreText} ${m.teamB}'
                        : 'التوقّع اتقفل — استنى النتيجة'),
              style: AppText.h(12, color: AppColors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: ScorePicker(team: m.teamA, value: a, onChanged: open ? (v) => setState(() => _a = v) : null),
                ),
                Text('-', style: AppText.h(30)),
                Expanded(
                  child: ScorePicker(team: m.teamB, value: b, onChanged: open ? (v) => setState(() => _b = v) : null),
                ),
              ],
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Pressable(
                onTap: _saving ? null : _save,
                child: Container(
                  decoration: BoxDecoration(
                    color: _saving ? AppColors.neutral500 : AppColors.accent,
                    borderRadius: AppRadius.md,
                  ),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.center,
                  child: Text(
                    it.mine == null ? 'سجّل توقّعي' : 'غيّر توقّعي',
                    style: AppText.h(14, color: AppColors.white),
                  ),
                ),
              ),
            )
          else if (it.mine == null)
            _note('مالحقتش تتوقّع في الماتش ده')
          else if (m.isFinished)
            _note(
              it.won
                  ? '🎉 فرق الأهداف صح! خدت +${Prediction.bonus} نقط'
                  : 'توقّعك ${it.mine!.scoreA} - ${it.mine!.scoreB} ماجاش المرة دي',
            ),
          if (it.summary != null) _note('${it.summary!.correct} من ${it.summary!.total} جابوا فرق الأهداف صح'),
        ],
      ),
    );
  }

  Widget _note(String t) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      t,
      textAlign: TextAlign.center,
      style: AppText.h(13, color: AppColors.neutral700),
    ),
  );
}
