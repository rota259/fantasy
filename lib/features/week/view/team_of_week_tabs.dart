part of 'team_of_week_screen.dart';

extension _ViewTabs on _View {
  /// «الجولة اللي خلصت» (نهائية) ↔ «الحالية لحد دلوقتي» (لايف) — على أرضية الملعب الغامقة.
  Widget _tabs(BuildContext context, TeamOfWeekState s) {
    final cubit = context.read<TeamOfWeekCubit>();
    Widget seg(String text, bool on, VoidCallback onTap, {bool live = false}) => Expanded(
      child: Pressable(
        onTap: on ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? AppColors.accent400 : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (live) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: on ? AppColors.black : AppColors.danger, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(text, style: AppText.h(12, color: on ? AppColors.black : AppColors.white)),
            ],
          ),
        ),
      ),
    );
    return Container(
      color: PitchColors.forest,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: [
            seg('الجولة اللي خلصت', !s.isCurrent, cubit.showFinished),
            seg('الحالية لحد دلوقتي', s.isCurrent, cubit.showLive, live: true),
          ],
        ),
      ),
    );
  }

  /// شريط فوق التشكيلة اللايف: إنها لسه بتتغيّر.
  Widget _liveNote() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: AppRadius.md),
    child: Text(
      'دي أعلى ٥ لحد دلوقتي من الماتشات اللي نتيجتها اتعتمدت — ممكن تتغيّر لحد ما الجولة تخلص '
      'لو حد جاب نقط أعلى وماتشه اتعتمد.',
      style: AppText.body(12, color: AppColors.neutral700),
    ),
  );
}
