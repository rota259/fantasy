part of 'manager_awards_screen.dart';

extension _ManagerAwardsScreenStateSections1 on _ManagerAwardsScreenState {
  /// شيل مرشّح — الـ controller بيتقفل بعد ما الحقل يختفي من الشاشة.
  void _remove(int i) {
    final c = _cands.removeAt(i);
    _update(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  }

  /// التصويت بيقفل نص ليل الجمعة (آخر يوم عرض الجولة).
  DateTime get _closesAt {
    var w = WeekWindow.current();
    if (DateTime.now().isAfter(w.cutoff.add(const Duration(hours: 20)))) w = w.next;
    return w.cutoff.add(const Duration(hours: 20));
  }

  Future<void> _publish(List<Player> players) async {
    final messenger = ScaffoldMessenger.of(context);
    final opts = <NewPollOption>[];
    for (final c in _cands) {
      final link = c.link.text.trim();
      if (c.playerId == null) continue;
      if (!VideoLink.isValid(link)) {
        messenger.showSnackBar(const SnackBar(content: Text('كل مرشّح لازم يبقى معاه لينك فيديو صحيح')));
        return;
      }
      final p = players.firstWhere((x) => x.id == c.playerId);
      opts.add((label: '${p.name} · ${p.team}', playerId: p.id, videoUrl: link, matchId: null));
    }
    if (opts.length < 2) {
      messenger.showSnackBar(const SnackBar(content: Text('محتاج مرشّحين اتنين على الأقل')));
      return;
    }
    _update(() => _busy = true);
    try {
      final kind = _kind == 'goal' ? PollKind.goalWeek : PollKind.saveWeek;
      await context.read<PollsRepository>().createAward(
        kind,
        _kind == 'goal' ? 'هدف الجولة' : 'تصدّي الجولة 🧤',
        opts,
        _closesAt,
      );
      messenger.showSnackBar(const SnackBar(content: Text('اتنشر التصويت ✓')));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    } finally {
      if (mounted) _update(() => _busy = false);
    }
  }

  Future<void> _season() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PollsRepository>().createSeasonAward(_kind);
      messenger.showSnackBar(const SnackBar(content: Text('اتعمل تصويت السنة من فايزين الجولات ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Widget _kindTab(String k, String label) {
    final on = _kind == k;
    return Pressable(
      onTap: () => _update(() => _kind = k),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: on ? AppColors.accent : null,
          border: Border.all(color: on ? AppColors.accent : AppColors.line, width: 1.4),
        ),
        child: Text(label, style: AppText.h(13, color: on ? AppColors.white : AppColors.ink)),
      ),
    );
  }

  Widget _button(String text, Color color, VoidCallback? onTap, {bool dark = true}) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: onTap == null ? AppColors.neutral500 : color,
        border: dark ? null : Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Text(text, style: AppText.h(13, color: dark ? AppColors.white : AppColors.ink)),
    ),
  );
}
