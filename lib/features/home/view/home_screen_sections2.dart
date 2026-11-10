part of 'home_screen.dart';

extension _HomeViewSections2 on _HomeView {
  Widget _side(String label, int value, {String? sub, Color? color}) => Column(
    children: [
      CountUp(
        value: value,
        style: AppText.h(26, color: color ?? AppColors.white, height: 1),
      ),
      const SizedBox(height: 2),
      Text(label, style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.6))),
      if (sub != null)
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(10, color: AppColors.white.withValues(alpha: 0.45)),
        ),
    ],
  );

  /// الماتش الجاي في منطقتك — الضغط بيفتح تشكيلة الجولة.
  Widget _nextMatch(BuildContext context, GameMatch? m, WeekWindow? open) {
    if (m == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: AppDecor.tile,
        child: Row(
          children: [
            Icon(Icons.event_busy_outlined, size: 20, color: AppColors.neutral500),
            const SizedBox(width: 10),
            Expanded(
              child: Text('مفيش ماتش قادم في منطقتك دلوقتي', style: AppText.body(13, color: AppColors.neutral700)),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Pressable(
        onTap: () => context.read<AppNavCubit>().setTab(AppTab.team),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecor.tile,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الماتش القادم${m.isChallenge ? ' · تحدّي الجولة' : ''}',
                style: AppText.kicker(color: AppColors.accent),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(17))),
                  Text('تشكيلتك ›', style: AppText.h(13, color: AppColors.accent)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)}'
                ' · لاعيبته بيتقفلوا ${arabicTime(m.dateTime.subtract(const Duration(hours: 1)))}',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
