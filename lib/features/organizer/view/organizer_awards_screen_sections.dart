part of 'organizer_awards_screen.dart';

extension _OrganizerAwardsScreenStateSections1 on _OrganizerAwardsScreenState {
  Future<(List<GameMatch>, List<AwardNomination>)> _load() async {
    final since = DateTime.now().subtract(const Duration(days: 10));
    final (matches, mine) = await (
      context.read<MatchesRepository>().fetchOrganizedBy(widget.organizerId),
      _polls.myNominations(),
    ).wait;
    final done = matches.where((m) => m.isFinished && !m.isVoid && m.dateTime.isAfter(since)).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return (done, mine);
  }

  Future<void> _remove(AwardNomination n) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _polls.removeNomination(n.optionId);
      messenger.showSnackBar(const SnackBar(content: Text('اتشال الترشيح ✓')));
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Widget _match(GameMatch m) => Pressable(
    onTap: () => _nominate(m),
    child: Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.tile,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.teamA} ${m.scoreA ?? 0} - ${m.scoreB ?? 0} ${m.teamB}', style: AppText.h(14)),
                Text(
                  '${arabicWeekday(m.dateTime)} ${m.dateTime.day}/${m.dateTime.month}',
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
            child: Text('+ رشّح', style: AppText.h(12, color: AppColors.white)),
          ),
        ],
      ),
    ),
  );

  Widget _nomination(AwardNomination n) => Container(
    margin: AppDecor.tileMargin,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: AppDecor.tile,
    child: Row(
      children: [
        Text(n.kind == PollKind.goalWeek ? '⚽' : '🧤', style: AppText.h(18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.label, style: AppText.h(13)),
              Text(
                '${n.votes} صوت${n.open ? '' : ' · التصويت خلص'}',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ],
          ),
        ),
        if (n.open)
          IconButton(
            tooltip: 'شيل الترشيح',
            onPressed: () => _remove(n),
            icon: Icon(Icons.delete_outline, color: AppColors.danger),
          ),
      ],
    ),
  );
}
