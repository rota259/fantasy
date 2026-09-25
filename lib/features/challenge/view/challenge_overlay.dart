import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../overlays/widgets/overlay_shell.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../cubit/challenge_cubit.dart';
import '../data/challenge_repository.dart';
import '../data/models/prediction.dart';
import '../widgets/score_picker.dart';

/// تحدّي الجولة: توقّع نتيجة الماتش اللي المدير اختاره — الصح ياخد +٥.
class ChallengeOverlay extends StatelessWidget {
  const ChallengeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => ChallengeCubit(c.read<ChallengeRepository>(), userId)..load(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  int? _a, _b; // المختار قبل الحفظ
  bool _saving = false;

  Future<void> _save(GameMatch m) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final err = await context.read<ChallengeCubit>().predict(_a ?? 0, _b ?? 0);
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
    return BlocBuilder<ChallengeCubit, ChallengeState>(
      builder: (context, s) => OverlayShell(
        title: 'تحدّي الجولة',
        subtitle: 'PREDICT & WIN +${Prediction.bonus}',
        onBack: context.read<AppNavCubit>().back,
        children: s.loading
            ? const [
                Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                ),
              ]
            : s.match == null
            ? [_note('المدير لسه ماختارش ماتش التحدّي')]
            : _content(s, s.match!),
      ),
    );
  }

  List<Widget> _content(ChallengeState s, GameMatch m) {
    final a = _a ?? s.mine?.scoreA ?? 0;
    final b = _b ?? s.mine?.scoreB ?? 0;
    final open = !m.isLocked && !m.isFinished;
    return [
      Container(
        width: double.infinity,
        color: AppColors.black,
        padding: const EdgeInsets.all(16),
        child: Text(
          open
              ? 'توقّع النتيجة بالظبط قبل ${arabicWeekday(m.deadline)} ${arabicTime(m.deadline)} واكسب +${Prediction.bonus} نقط 🎯'
              : (m.isFinished ? 'الماتش خلص: ${m.teamA} ${m.scoreText} ${m.teamB}' : 'التوقّع اتقفل — استنى النتيجة'),
          style: AppText.h(13, color: AppColors.white),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
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
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: _saving ? null : () => _save(m),
            child: Container(
              color: _saving ? AppColors.neutral500 : AppColors.accent,
              padding: const EdgeInsets.all(13),
              alignment: Alignment.center,
              child: Text(s.mine == null ? 'سجّل توقّعي' : 'غيّر توقّعي', style: AppText.h(14, color: AppColors.white)),
            ),
          ),
        )
      else if (s.mine == null)
        _note('مالحقتش تتوقّع في الماتش ده')
      else if (m.isFinished)
        _note(
          s.won
              ? '🎉 توقّعك صح! خدت +${Prediction.bonus} نقط'
              : 'توقّعك ${s.mine!.scoreA} - ${s.mine!.scoreB} ماجاش المرة دي',
        ),
      if (s.summary != null) _note('${s.summary!.correct} من ${s.summary!.total} توقّعوها صح'),
    ];
  }

  Widget _note(String t) => Padding(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: AppText.h(14, color: AppColors.neutral700),
      ),
    ),
  );
}
