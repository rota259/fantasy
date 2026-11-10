part of 'challenge_card.dart';

extension _ChallengeCardStateSections1 on _ChallengeCardState {
  /// حفظ كل اللي اتجاوب: فرق الأهداف (لو موجود) + باقي الأنواع.
  Future<void> _save() async {
    final it = widget.item;
    final m = it.match;
    final x = it.extras;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ChallengeCubit>();
    _update(() => _saving = true);
    String? err;
    if (x.has(ChallengeMode.diff)) {
      err = await cubit.predict(m, _a ?? it.mine?.scoreA ?? 0, _b ?? it.mine?.scoreB ?? 0);
    }
    if (err == null && x.modes.any((k) => k != ChallengeMode.diff)) {
      err = await cubit.answer(m, _ans ?? x.mine);
    }
    if (!mounted) return;
    _update(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'اتسجّلت إجاباتك ✓ — تقدر تغيّرها لحد ${arabicTime(m.deadline)}'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
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
