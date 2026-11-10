part of 'totw_reveal_screen.dart';

extension _TotwRevealScreenStateSections1 on _TotwRevealScreenState {
  void _next() {
    if (!mounted || _shown >= _order.length) return;
    _update(() => _shown++);
    AppSounds.play(AppSounds.totwReveal, channel: 'reveal');
    _shown == _order.length ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
    if (_shown == _order.length) _timer?.cancel();
  }

  /// الكارت اللي بينزل دلوقتي + اللي اتكشفوا فوق.
  Widget _revealing() {
    final i = _shown - 1;
    final isStar = i == _order.length - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('⭐ تشكيلة الجولة', style: AppText.h(22, color: Colors.white)),
        const SizedBox(height: 26),
        if (i >= 0)
          TweenAnimationBuilder<double>(
            key: ValueKey(i),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: Motion.reduced(context) ? 1 : 650),
            curve: Curves.easeOutBack,
            builder: (_, t, c) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, -220 * (1 - t)),
                child: Transform.scale(scale: 1.4 - 0.4 * t, child: c),
              ),
            ),
            child: _bigCard(_order[i], star: isStar),
          ),
      ],
    );
  }

  Widget _bigCard(WeekPlayer p, {bool star = false}) {
    // نفس ألوان الملعب: فريم أخضر غامق (النجم فريمه دهب معدني بيلمع) · خط أبيض · نجيلة خضرا · اللاعب بالدهب
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)));
    final inner = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PitchColors.line, width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PitchColors.grassStripe, PitchColors.grass, PitchColors.grassStripe, PitchColors.grass],
          stops: [0, 0.35, 0.65, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(p.positionAr, style: AppText.kicker(color: Colors.white)),
          const SizedBox(height: 10),
          GoldAvatar(player: p, size: 104, card: true),
          const SizedBox(height: 10),
          Text(
            p.name,
            textAlign: TextAlign.center,
            style: AppText.h(18, color: Colors.white),
          ),
          Text(p.team, style: AppText.body(11, color: Colors.white70)),
          const SizedBox(height: 8),
          GoldShine(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Text('${p.points}', style: AppText.h(32, color: const Color(0xFF3A2600))),
          ),
          if (star) ...[
            const SizedBox(height: 6),
            Text('⭐ نجم الجولة', style: AppText.h(14, color: const Color(0xFFFFE7A0))),
          ],
        ],
      ),
    );
    return Container(
      width: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFFC9971C).withValues(alpha: star ? 0.7 : 0.3), blurRadius: 30)],
      ),
      child: star
          ? GoldShine(shape: shape, padding: const EdgeInsets.all(7), child: inner)
          : Container(
              padding: const EdgeInsets.all(7),
              decoration: ShapeDecoration(color: PitchColors.forest, shape: shape),
              child: inner,
            ),
    );
  }

  /// النهاية: كارت story جاهز للشير.
  Widget _final() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: RepaintBoundary(
                key: _cardKey,
                child: TotwStoryCard(team: widget.team, label: widget.label, refCode: widget.refCode),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () => ShareCard.share(
                  _cardKey,
                  'تشكيلة الجولة في ${widget.label} ⭐ — نجمها ${_star?.name ?? ''}\nالعب الخماسي'
                  '${widget.refCode == null ? '' : ' بكود ${widget.refCode}'}',
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('شيّر'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('تمام'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
