part of 'tournament_matches_tab.dart';

extension _TournamentMatchesTabSections1 on TournamentMatchesTab {
  Widget _row(BuildContext context, GameMatch m) {
    final needsWinner =
        runs &&
        m.isFinished &&
        m.winner == null &&
        m.scoreA == m.scoreB &&
        m.stage != null &&
        !m.stage!.startsWith('مجموعة') &&
        m.stage != 'الدوري';
    final live = m.timeSet && m.hasStarted && !m.isFinished;
    final canSetTime = runs && !m.isFinished && !live;
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: m.timeSet ? () => MatchCenterScreen.open(context, m) : null,
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.all(14),
        decoration: AppDecor.tile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.teamA,
                    textAlign: TextAlign.end,
                    style: AppText.h(14, color: TournamentMatchesTab._c(m, m.teamA)),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: live ? AppColors.danger : AppColors.black,
                    borderRadius: AppRadius.md,
                  ),
                  child: Text(
                    m.isFinished || live
                        ? '${m.scoreA ?? 0} - ${m.scoreB ?? 0}'
                        : (m.timeSet ? arabicTime(m.dateTime) : 'ضد'),
                    style: AppText.h(13, color: AppColors.white),
                  ),
                ),
                Expanded(
                  child: Text(m.teamB, style: AppText.h(14, color: TournamentMatchesTab._c(m, m.teamB))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              m.timeSet
                  ? '${arabicWeekday(m.dateTime)} ${m.dateTime.day}/${m.dateTime.month}${m.winner != null && m.scoreA == m.scoreB ? ' · ${m.winner} كسب بضربات الجزاء' : ''}'
                  : 'الميعاد لسه متحددش',
              textAlign: TextAlign.center,
              style: AppText.body(10, color: AppColors.neutral600),
            ),
            if (needsWinner)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('تعادل — مين كسب بضربات الجزاء؟', style: AppText.h(12, color: AppColors.bronze)),
                    ),
                    for (final team in m.teams)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: OutlinedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final err = await context.read<TournamentCubit>().setWinner(m.id, team);
                            messenger.showSnackBar(SnackBar(content: Text(err ?? '$team اتأهل ✓')));
                          },
                          child: Text(team),
                        ),
                      ),
                  ],
                ),
              ),
            if (runs && !m.isFinished)
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  if (canSetTime)
                    TextButton.icon(
                      onPressed: () => _pickTime(context, m),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(m.timeSet ? 'غيّر الميعاد' : 'حدّد الميعاد'),
                    ),
                  if (m.timeSet)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ManagerMatchScreen.of(context, m))),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('إدارة الماتش'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
