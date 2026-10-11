import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../matches/widgets/match_format.dart';
import '../cubit/challenge_cubit.dart';
import '../data/models/challenge_extras.dart';
import 'challenge_sections.dart';
import 'score_picker.dart';

/// كارت تحدّي واحد بالأنواع اللي المدير اختارها (فرق الأهداف · مين فيهم؟ · ٣ أسئلة · المعكوس):
/// جاوب قبل الماتش بساعة، وبعده كل قسم بيقول صح ولا لأ وكسبت كام.
class ChallengeCard extends StatefulWidget {
  const ChallengeCard({super.key, required this.item});

  final ChallengeItem item;

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard> {
  int? _a, _b; // فرق الأهداف: المختار قبل الحفظ
  ChallengeAnswers? _ans; // باقي الأنواع قبل الحفظ
  bool _saving = false;

  /// حفظ كل اللي اتجاوب: فرق الأهداف (لو موجود) + باقي الأنواع.
  Future<void> _save() async {
    final it = widget.item;
    final m = it.match;
    final x = it.extras;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ChallengeCubit>();
    setState(() => _saving = true);
    String? err;
    if (x.has(ChallengeMode.diff)) {
      err = await cubit.predict(m, _a ?? it.mine?.scoreA ?? 0, _b ?? it.mine?.scoreB ?? 0);
    }
    if (err == null && x.modes.any((k) => k != ChallengeMode.diff)) {
      err = await cubit.answer(m, _ans ?? x.mine);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'اتسجّلت إجاباتك ✓ — تقدر تغيّرها لحد ${arabicTime(m.deadline)}'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final m = it.match;
    final x = it.extras;
    final a = _a ?? it.mine?.scoreA ?? 0;
    final b = _b ?? it.mine?.scoreB ?? 0;
    final open = !m.isLocked && !m.isFinished;
    final answered = it.mine != null || x.mine != const ChallengeAnswers();
    final streak = context.select<ChallengeCubit, int>((c) => c.state.streak);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(16, color: AppColors.white)),
                const SizedBox(height: 2),
                Text(
                  open
                      ? 'جاوب قبل ${arabicWeekday(m.deadline)} ${arabicTime(m.deadline)}'
                      : (m.isFinished
                            ? 'الماتش خلص: ${m.scoreText}${x.total > 0 ? ' · كسبت +${x.total}' : ''}'
                            : 'التوقّع اتقفل — استنى النتيجة'),
                  style: AppText.body(12, color: AppColors.white.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          if (x.has(ChallengeMode.diff))
            ChallengeSection(
              mode: ChallengeMode.diff,
              points: m.isFinished && it.mine != null ? (x.points[ChallengeMode.diff] ?? (it.won ? 5 : 0)) : null,
              note: open && streak > 0
                  ? 'سلسلتك $streak ورا بعض — لو جبتها صح المرة دي +${streak == 1 ? 7 : 10}'
                  : (m.isFinished && x.streak >= 2 ? 'صح $streak مرات ورا بعض' : null),
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
          ChallengeSections(
            match: m,
            extras: x,
            answers: _ans ?? x.mine,
            open: open,
            onChanged: (v) => setState(() => _ans = v),
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
                  child: Text(answered ? 'غيّر إجاباتي' : 'سجّل إجاباتي', style: AppText.h(14, color: AppColors.white)),
                ),
              ),
            )
          else if (!answered)
            _note('مالحقتش تجاوب في التحدّي ده')
          else
            const SizedBox(height: 12),
          if (it.summary != null && x.has(ChallengeMode.diff))
            _note('${it.summary!.correct} من ${it.summary!.total} جابوا فرق الأهداف صح'),
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
