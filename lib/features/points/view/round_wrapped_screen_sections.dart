part of 'round_wrapped_screen.dart';

extension _RoundWrappedScreenStateSections1 on _RoundWrappedScreenState {
  void _go(int d) {
    final n = (_i + d).clamp(0, _RoundWrappedScreenState._slides - 1);
    if (n == _i && d > 0) return _bar.stop(); // آخر سلايد بيفضل
    _update(() => _i = n);
    _bar.forward(from: 0);
  }

  Widget _progress(Color fg) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    child: Row(
      children: [
        for (var k = 0; k < _RoundWrappedScreenState._slides; k++)
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: fg.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(2)),
              alignment: AlignmentDirectional.centerStart,
              child: k < _i
                  ? Container(color: fg)
                  : k == _i
                  ? AnimatedBuilder(
                      animation: _bar,
                      builder: (_, _) => FractionallySizedBox(
                        widthFactor: _bar.value,
                        child: Container(color: fg),
                      ),
                    )
                  : null,
            ),
          ),
      ],
    ),
  );

  Widget _name(String? name) => Text(
    name ?? '—',
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: AppText.h(54, color: _tone.accent, height: 1.05),
  );

  Widget _slide(RoundRecap r) {
    final m = r.moved;
    return switch (_i) {
      0 => WrappedSlide(
        tone: _tone,
        index: 1,
        title: 'جولتك',
        value: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: CountUp(
            value: r.points,
            style: AppText.h(150, color: _tone.accent, height: 1),
          ),
        ),
        sub: 'نقطة في ${widget.window.label}',
        extra: r.chip == null ? null : 'لعبت بكارت الجولة دي',
        extraIcon: Icons.style_rounded,
      ),
      1 => WrappedSlide(
        tone: _tone,
        index: 2,
        title: 'أحسن اختيار ليك',
        value: _name(r.bestName),
        sub: '${r.bestPoints} نقطة',
        extra: r.bestPoints >= 10 ? 'عين صقر' : null,
        extraIcon: Icons.visibility_rounded,
      ),
      2 => WrappedSlide(
        tone: _tone,
        index: 3,
        title: 'الكابتن',
        value: _name(r.captainName),
        sub: '${r.captainPoints} × ٢ = ${r.captainPoints * 2} نقطة',
        extra: r.captainPoints * 2 >= 10 ? 'كابتن صح' : 'المرة الجاية تختار أحسن',
        extraIcon: r.captainPoints * 2 >= 10 ? Icons.local_fire_department_rounded : Icons.refresh_rounded,
      ),
      3 => Stack(
        children: [
          if (m > 0) const Positioned.fill(child: ConfettiBurst(count: 60)),
          WrappedSlide(
            tone: _tone,
            index: 4,
            title: 'ترتيبك في الدوري العام',
            value: _number('#${r.rankNow}', 130),
            sub: 'من ${r.users} لاعب',
            extra: m > 0 ? 'طلعت $m مركز' : (m < 0 ? 'نزلت ${-m} مركز' : 'ثابت في مكانك'),
            extraIcon: m > 0
                ? Icons.arrow_upward_rounded
                : (m < 0 ? Icons.arrow_downward_rounded : Icons.drag_handle_rounded),
          ),
        ],
      ),
      _ => _share(r),
    };
  }

  Widget _share(RoundRecap r) {
    final user = context.read<AuthCubit>().state.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: RoundStoryCard(
                    recap: r,
                    name: user?.name ?? '',
                    label: widget.window.label,
                    refCode: user?.refCode,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: StoryColors.lime,
              foregroundColor: StoryColors.ink,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () => ShareCard.share(
              _cardKey,
              'جبت ${r.points} نقطة الجولة دي في الخماسي ⚽ وترتيبي #${r.rankNow}'
              '${user?.refCode == null ? '' : '\nالعب معايا بكود ${user!.refCode}'}',
            ),
            icon: const Icon(Icons.ios_share),
            label: const Text('شيّر جولتك'),
          ),
        ],
      ),
    );
  }
}
