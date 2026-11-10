part of 'fixtures_overlay.dart';

extension _FixturesViewSections1 on _FixturesView {
  Widget _deadline(GameMatch m) {
    return Container(
      decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: Row(
        children: [
          BlinkDot(color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            'يقفل ${arabicWeekday(m.deadline)} ${arabicTime(m.deadline)} · اختر قبلها',
            style: AppText.h(11, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  List<Widget> _upcoming(BuildContext context, MatchesState s) {
    final groups = <String, List<GameMatch>>{};
    for (final m in s.matches) {
      groups.putIfAbsent('${arabicWeekday(m.dateTime)} ${m.dateTime.day}/${m.dateTime.month}', () => []).add(m);
    }
    return [
      for (final entry in groups.entries) ...[
        _dayHeader(entry.key),
        for (final (i, m) in entry.value.indexed)
          FadeSlideIn(index: i, child: _row(context, m, s.follows.contains(m.id))),
      ],
      _legend(),
    ];
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.all(30),
    child: Center(
      child: EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'مفيش ماتشات قادمة',
        hint: 'مديرين منطقتك بينزّلوا الماتشات قبل كل جولة',
      ),
    ),
  );

  Widget _row(BuildContext context, GameMatch m, bool following) {
    final uid = userId;
    final live = m.hasStarted && !m.isFinished;
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: () => MatchCenterScreen.open(context, m),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppDecor.tile,
        child: Row(
          children: [
            FdrChip(m.fdr),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${m.teamA} ', style: AppText.h(13)),
                        TextSpan(
                          text: 'ضد',
                          style: AppText.body(13, color: AppColors.neutral700),
                        ),
                        TextSpan(text: ' ${m.teamB}', style: AppText.h(13)),
                      ],
                    ),
                  ),
                  Text(
                    live
                        ? '● لايف · ${m.scoreA ?? 0} - ${m.scoreB ?? 0}${m.isChallenge ? ' · تحدّي الجولة' : ''}'
                        : '${arabicTime(m.dateTime)}${m.isChallenge ? ' · تحدّي الجولة' : ''}',
                    style: AppText.body(10, color: live ? AppColors.danger : AppColors.neutral600),
                  ),
                ],
              ),
            ),
            if (uid != null)
              FollowButton(
                matchId: m.id,
                userId: uid,
                following: following,
                onChanged: (on) => context.read<MatchesCubit>().setFollow(m.id, on),
              ),
          ],
        ),
      ),
    );
  }
}
