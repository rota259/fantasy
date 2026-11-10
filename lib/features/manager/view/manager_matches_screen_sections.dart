part of 'manager_matches_screen.dart';

extension _ManagerMatchesScreenStateSections1 on _ManagerMatchesScreenState {
  Future<void> _addMatch() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ManagerAddMatchScreen(matchesRepo: widget.matchesRepo)),
    );
    if (added == true) _reload();
  }

  Future<void> _editMatch(GameMatch m) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerAddMatchScreen(matchesRepo: widget.matchesRepo, editing: m),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(GameMatch m) async {
    final ok = await confirmDeleteMatch(context, m);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await widget.matchesRepo.deleteMatch(m.id);
      if (n == 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('مينفعش تحذف الماتش ده (بدأ أو مش بتاعك)'),
            duration: Duration(milliseconds: 2600),
          ),
        );
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('اتحذف الماتش ✓')));
      _reload();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(dbMessage(e, fallback: 'فشل الحذف')),
          duration: const Duration(milliseconds: 2600),
        ),
      );
    }
  }

  Widget _row(GameMatch m) {
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManagerMatchScreen(
            match: m,
            playersRepo: widget.playersRepo,
            eventsRepo: widget.eventsRepo,
            lineupRepo: widget.lineupRepo,
          ),
        ),
      ),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: AppDecor.tile,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(14))),
                      const SizedBox(width: 6),
                      ReviewStatusChip(match: m),
                    ],
                  ),
                  Text(
                    m.timeSet
                        ? 'GW${m.week} · ${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)} · ${m.isFinished ? 'انتهى ${m.scoreText}' : 'قادم'}'
                        : '${m.stage ?? 'بطولة'} · الميعاد لسه متحددش — حدّده من صفحة البطولة',
                    style: AppText.body(10, color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            Text('إدارة ›', style: AppText.h(12, color: AppColors.accent)),
            const SizedBox(width: 8),
            Pressable(
              onTap: () => _editMatch(m),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined, size: 20, color: AppColors.neutral700),
              ),
            ),
            Pressable(
              onTap: () => _confirmDelete(m),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
