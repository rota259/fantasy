part of 'pick_pitch.dart';

extension _PickPitchSections1 on PickPitch {
  List<Player> _starting(bool Function(Player) test) {
    final out = <Player>[];
    state.sel.forEach((id, st) {
      final p = state.playerById(id);
      if (st == 'starting' && p != null && test(p)) out.add(p);
    });
    return out;
  }

  List<Player> get _bench {
    final out = <Player>[];
    state.sel.forEach((id, st) {
      final p = state.playerById(id);
      if (st == 'bench' && p != null) out.add(p);
    });
    return out;
  }

  PitchToken _token(double l, double t, Player? p, String kind, [int order = 0]) => PitchToken(
    leftPct: l,
    topPct: t,
    // اللاعب بيدخل مكانه بتكبير خفيف (والمكان الفاضي بيرجع كده برضه)
    child: AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, a) => ScaleTransition(
        scale: a,
        child: FadeTransition(opacity: a, child: child),
      ),
      child: KeyedSubtree(
        key: ValueKey(p?.id ?? 'empty-$l-$t'),
        child: _entry(
          order,
          _drop(p, kind, p == null ? _plus(() => onSlotTap(kind)) : _filled(p, () => onPlayerTap(p))),
        ),
      ),
    ),
  );

  Widget _entry(int order, Widget child) => entryKey == null
      ? child
      : FadeSlideIn(key: ValueKey('$entryKey-$order'), index: order * 2, offset: 40, child: child);

  /// هدف إفلات: على لاعب = تبديل، على مكان فاضي = ينتقل له.
  Widget _drop(Player? p, String kind, Widget child) {
    if (!_draggable) return child;
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != p?.id,
      onAcceptWithDetails: (d) {
        HapticFeedback.selectionClick();
        p == null ? onMoveTo?.call(d.data, kind) : onSwap!(d.data, p.id);
      },
      builder: (_, hover, _) => AnimatedScale(scale: hover.isEmpty ? 1 : 1.15, duration: Motion.fast, child: child),
    );
  }

  Widget _filled(Player p, VoidCallback onTap) {
    final body = _player(p, onTap);
    if (!_draggable || state.isLocked(p.id)) return body;
    return LongPressDraggable<String>(
      data: p.id,
      onDragStarted: HapticFeedback.mediumImpact,
      feedback: Material(
        type: MaterialType.transparency,
        child: Transform.scale(scale: 1.15, child: PickPitch._shirt(p, state.captainId == p.id)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: body),
      child: body,
    );
  }

  Widget _player(Player p, VoidCallback onTap) {
    final badge = state.captainId == p.id ? 'C' : (state.viceId == p.id ? 'V' : null);
    final live = liveTeams.contains(p.team);
    final avatar = PulseGlow(enabled: live, color: AppColors.danger, child: PickPitch._shirt(p, badge == 'C'));
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                avatar,
                if (state.isLocked(p.id)) const Positioned(bottom: -2, left: -4, child: _LockBadge()),
                Positioned(
                  top: -6,
                  right: -6,
                  // الكابتن/البديل: الشارة بتتقلب لما تتغيّر
                  child: FlipSwitcher(
                    child: badge == null
                        ? const SizedBox(key: ValueKey('none'), width: 20, height: 20)
                        : Container(
                            key: ValueKey(badge),
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: badge == 'C' ? const Color(0xFFF2C14E) : AppColors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              badge,
                              style: AppText.h(9, color: badge == 'C' ? AppColors.black : AppColors.white),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // اسم اللاعب على شريحة بيضا ناعمة والكلام بالأسود
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Text(
                p.shortName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.h(10, color: Colors.black),
              ),
            ),
            if (liveTeams.contains(p.team)) _live(),
            if (pointsFor != null) PointsPop(value: pointsFor![p.id] ?? 0),
          ],
        ),
      ),
    );
  }

  /// شارة "بيلعب دلوقتي".
  Widget _live() => Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(color: AppColors.danger, borderRadius: AppRadius.sm),
    child: Text('● لايف', style: AppText.h(8, color: AppColors.white)),
  );
}
