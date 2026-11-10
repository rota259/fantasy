part of 'manager_challenge_screen.dart';

extension _ManagerChallengeScreenStateSections1 on _ManagerChallengeScreenState {
  /// الماتشات اللي فاضل عليها أكتر من ساعتين (الناس تلحق تتوقّع).
  Future<List<GameMatch>> _load() async {
    final id = widget.organizerId;
    final all = id == null ? await _matches.fetchAll() : await _matches.fetchOrganizedBy(id);
    final from = DateTime.now().add(Duration(hours: kTestMode ? 0 : 2));
    // ماتشات البطولات اللي ميعادها لسه متحددش مش بتتعرض
    return all.where((m) => m.timeSet && !m.isFinished && m.dateTime.isAfter(from)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _choose(GameMatch m) async {
    // أنواع التحدّي: واحد أو أكتر أو الأربعة
    final setup = await showChallengeSetupSheet(context, m);
    if (setup == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<ChallengeRepository>();
    _update(() => _busy = true);
    try {
      await repo.setChallenge(m.id, modes: setup.modes, duelA: setup.duelA, duelB: setup.duelB);
      messenger.showSnackBar(const SnackBar(content: Text('اتعلن التحدّي واتبعت إشعار ✓')));
      _update(() {
        _future = _load();
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    } finally {
      if (mounted) _update(() => _busy = false);
    }
  }

  Widget _row(GameMatch m) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: AppDecor.softDivider,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(14)),
              Text(
                '${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)}',
                style: AppText.body(10, color: AppColors.neutral700),
              ),
            ],
          ),
        ),
        if (m.isChallenge)
          Text('تحدّي', style: AppText.h(12, color: AppColors.accent))
        else
          Pressable(
            onTap: _busy ? null : () => _choose(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.line, width: 1.2),
              ),
              child: Text('اختار', style: AppText.h(11)),
            ),
          ),
      ],
    ),
  );
}
