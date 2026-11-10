part of 'tournament_fantasy_tab.dart';

extension _TournamentFantasyTabStateSections1 on _TournamentFantasyTabState {
  Future<void> _load() async {
    try {
      final d = await _repo.fantasy(widget.tournamentId);
      if (!mounted) return;
      _update(() {
        _data = d;
        _failed = false;
        _sel
          ..clear()
          ..addAll(d.mine);
        _captain = d.captain;
      });
    } catch (_) {
      if (mounted) _update(() => _failed = true);
    }
  }

  FantasyPlayer? _p(String id) {
    for (final p in _data!.players) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// اختار/شيل لاعب — بنفس شروط السيرفر.
  void _toggle(FantasyPlayer p) {
    if (!_data!.open) return;
    if (_sel.contains(p.id)) {
      _update(() {
        _sel.remove(p.id);
        if (_captain == p.id) _captain = null;
      });
      return;
    }
    final picked = [for (final id in _sel) _p(id)].whereType<FantasyPlayer>().toList();
    if (picked.length >= 5) return _snack('التشكيلة ٥ لاعيبة — شيل واحد الأول');
    if (p.gk && picked.any((x) => x.gk)) return _snack('حارس واحد بس');
    if (!p.gk && picked.where((x) => !x.gk).length >= 4) return _snack('٤ لاعيبة وحارس — لسه محتاج الحارس');
    if (picked.where((x) => x.team == p.team).length >= 2) return _snack('بحد أقصى لاعبين من نفس الفريق');
    _update(() {
      _sel.add(p.id);
      _captain ??= p.id;
    });
  }

  Future<void> _save() async {
    if (_sel.length != 5) return _snack('اختار ٥ لاعيبة (حارس + ٤)');
    if (_captain == null) return _snack('دوس على لاعب من تشكيلتك فوق عشان يبقى الكابتن');
    _update(() => _saving = true);
    try {
      await _repo.saveFantasy(widget.tournamentId, _sel, _captain!);
      await _load();
      if (mounted) _snack('تشكيلتك في البطولة اتحفظت ✓');
    } catch (e) {
      if (mounted) _snack(dbMessage(e));
    } finally {
      if (mounted) _update(() => _saving = false);
    }
  }

  Widget _summary(TournamentFantasy d) {
    final note = !d.canPlay
        ? 'فانتازي البطولة لأهل منطقتها بس (وحساب المدير مش بيلعب)'
        : d.finished
        ? 'البطولة خلصت — ده الترتيب النهائي'
        : d.live
        ? 'فيه ماتش شغال — التشكيلة بتتفتح تاني لما يخلص'
        : 'اختار ٥ من فرق البطولة: حارس + ٤، وبحد أقصى ٢ من نفس الفريق. تقدر تغيّرهم بين الماتشات.';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تشكيلتي في البطولة', style: AppText.h(15, color: AppColors.white)),
                const SizedBox(height: 2),
                Text(note, style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.75), height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              CountUp(
                value: d.myPoints,
                style: AppText.h(30, color: AppColors.white, height: 1),
              ),
              Text(
                d.myRank == null ? 'نقطة' : 'نقطة · #${d.myRank}',
                style: AppText.body(11, color: AppColors.accent400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// الخمسة المختارين — الضغط على واحد = كابتن (×٢).
  Widget _lineup(TournamentFantasy d) {
    if (!d.canPlay) return const SizedBox.shrink();
    final picked = [for (final id in _sel) _p(id)].whereType<FantasyPlayer>().toList()
      ..sort((a, b) => (a.gk ? 0 : 1).compareTo(b.gk ? 0 : 1));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: AppDecor.tile,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (var i = 0; i < 5; i++) i < picked.length ? _token(picked[i], d.open) : _empty()],
          ),
          if (picked.isNotEmpty && d.open)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('دوس على لاعب عشان يبقى الكابتن (×٢)', style: AppText.body(11, color: AppColors.neutral700)),
            ),
        ],
      ),
    );
  }

  Widget _empty() => SizedBox(
    width: 58,
    child: Jersey(
      label: '+',
      size: 46,
      style: JerseyStyle(
        body: [AppColors.neutral300, AppColors.neutral200],
        trim: AppColors.neutral500,
        ink: AppColors.neutral700,
        shine: 0,
      ),
    ),
  );
}
