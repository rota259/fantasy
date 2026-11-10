part of 'pick_pitch.dart';

extension _PickPitchSections2 on PickPitch {
  /// مكان احتياطي: هدف إفلات + اللاعب نفسه بيتسحب + دخول متتابع.
  Widget _benchCell(Player? p, int order) {
    Widget slot = _benchSlot(p);
    if (_draggable && p != null) {
      slot = LongPressDraggable<String>(
        data: p.id,
        onDragStarted: HapticFeedback.mediumImpact,
        feedback: Material(type: MaterialType.transparency, child: PickPitch._avatar(p, 48)),
        childWhenDragging: Opacity(opacity: 0.3, child: slot),
        child: slot,
      );
    }
    return _entry(order, _drop(p, 'bench', slot));
  }

  Widget _benchSlot(Player? p) {
    if (p == null) {
      return Pressable(
        onTap: () => onSlotTap('bench'),
        child: Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.divider, width: 2),
          ),
          child: Text('+ احتياطي', style: AppText.h(12, color: AppColors.neutral600)),
        ),
      );
    }
    return Pressable(
      onTap: () => onPlayerTap(p),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: liveTeams.contains(p.team) ? AppColors.danger.withValues(alpha: 0.08) : null,
          border: Border.all(
            color: liveTeams.contains(p.team) ? AppColors.danger : AppColors.line,
            width: liveTeams.contains(p.team) ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            PickPitch._shirt(p, false, 30),
            const SizedBox(width: 8),
            Expanded(
              child: Text(p.shortName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(12)),
            ),
            // الاحتياطي نقطه بتظهر بس مش بتتحسب
            if (pointsFor != null) Text('${pointsFor![p.id] ?? 0}', style: AppText.h(12, color: AppColors.neutral500)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final gk = _starting((p) => p.position == 'GK');
    final out = _starting((p) => p.position != 'GK');

    Player? at(List<Player> l, int i) => i < l.length ? l[i] : null;

    final tokens = [
      _token(50, 86, at(gk, 0), 'gk', 0),
      _token(29, 20, at(out, 0), 'out', 1),
      _token(71, 20, at(out, 1), 'out', 2),
      _token(16, 60, at(out, 2), 'out', 3),
      _token(84, 60, at(out, 3), 'out', 4),
    ];

    final bench = _bench;
    return Column(
      children: [
        FormationPitch(height: 370, tokens: tokens, framed: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Row(
            children: [
              Text('الاحتياطي', style: AppText.kicker(color: AppColors.accent)),
              const Spacer(),
              Text('${bench.length}/2', style: AppText.h(12)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(child: _benchCell(at(bench, 0), 5)),
              const SizedBox(width: 10),
              Expanded(child: _benchCell(at(bench, 1), 6)),
            ],
          ),
        ),
      ],
    );
  }
}

/// قفل صغير على اللاعب اللي ماتشه بدأ أو فاضل عليه أقل من ساعة.
class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) => const CircleAvatar(
    radius: 10,
    backgroundColor: Color(0xE6000000),
    child: Icon(Icons.lock, size: 12, color: Colors.white),
  );
}
