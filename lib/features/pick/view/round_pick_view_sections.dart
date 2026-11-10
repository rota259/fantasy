part of 'round_pick_view.dart';

extension _ViewStateSections1 on _ViewState {
  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final chips = context.read<ChipsCubit>();
    final cubit = context.read<RoundPickCubit>();
    final cost = cubit.state.transferCost;
    if (cost > 0 && !await _confirmCost(context, cubit.state.transfers, cubit.state.locks.free, cost)) return;
    final err = await cubit.save();
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'اتحفظت تشكيلة الجولة ✓ — تقدر تفعّل كارت دلوقتي لو عايز'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
        duration: Duration(milliseconds: err == null ? 2200 : 4000),
      ),
    );
    if (err == null) {
      chips.load(); // الكروت بتحتاج تشكيلة محفوظة
      HapticFeedback.mediumImpact();
      if (mounted) _update(() => _entry = DateTime.now().millisecondsSinceEpoch);
    }
  }

  Widget _body(BuildContext context, bool editable) {
    return BlocBuilder<RoundPickCubit, RoundPickState>(
      builder: (context, s) {
        if (s.isLoading) return const SkeletonList();
        if (s.players.isEmpty) {
          return _note('لسه مفيش لاعيبة في منطقتك — أول ما المديرين ينزّلوا فرقهم هتلاقيهم هنا');
        }
        final cubit = context.read<RoundPickCubit>();
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            PickCounts(state: s),
            if (s.fromLastRound && editable)
              PickBanner(
                text: 'دي تشكيلتك من الجولة اللي فاتت — احفظها عشان تتحسب في الجولة دي',
                color: AppColors.info,
              ),
            if (!s.saved && !editable) PickBanner(text: 'معملتش تشكيلة للجولة دي', color: AppColors.neutral600),
            BlocBuilder<LiveTeamsCubit, Set<String>>(
              builder: (context, live) => PickPitch(
                state: s,
                liveTeams: live,
                entryKey: _entry,
                // السحب والإفلات: لاعب على لاعب = تبديل، على مكان فاضي = ينتقل
                onSwap: editable ? cubit.swap : null,
                onMoveTo: editable ? (id, kind) => cubit.setStatus(id, kind == 'bench' ? 'bench' : 'starting') : null,
                onSlotTap: editable ? (kind) => showAddPlayerSheet(context, cubit, s, kind) : (_) {},
                // مقفولة: الضغط على لاعب = اللي عمله في الجولة
                onPlayerTap: editable
                    ? (p) => showPlayerOptionsSheet(context, cubit, s, p)
                    : (p) => showPlayerRoundSheetFor(context, p, window),
              ),
            ),
            const ChipsBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Text(
                'دوس مطوّل على لاعب واسحبه على لاعب تاني يتبدّلوا، أو على مكان فاضي ينتقل له.\n'
                'القواعد: ٧ لاعيبة من أي فرق في منطقتك — ٥ أساسي (حارس واحد) + ٢ احتياطي.\n'
                'لازم كابتن (×٢) وكابتن بديل (بياخد المضاعفة لو الكابتن ملعبش ولا ماتش في الجولة).\n'
                'نقط كل لاعب = كل اللي عمله في ماتشات الجولة.\n'
                'كل لاعب بيتقفل قبل ماتشه بساعة (القفل) — بعدها ميتشالش ولا يتغيّر مكانه ولا الكابتن يتنقل منه.\n'
                'التغيير = لاعب مكانش في تشكيلتك الجولة اللي فاتت. كل جولة بتاخد تغيير ببلاش، واللي متستخدمش بيتجمّع '
                '(آخره ٥) — وكل تغيير فوق المجاني −٤ نقط.\n'
                'الكروت (كلها) لازم تتفعّل قبل ما أول لاعب في تشكيلتك يتقفل.',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ),
          ],
        );
      },
    );
  }

  /// تأكيد قبل حفظ تغييرات هتخصم نقط.
  Future<bool> _confirmCost(BuildContext context, int transfers, int free, int cost) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('هيتخصم $cost نقط'),
          content: Text('عملت $transfers تغييرات وعندك $free ببلاش — كل تغيير زيادة −٤. تحفظ؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لأ')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('احفظ')),
          ],
        ),
      ) ??
      false;

  Widget _note(String t) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: AppText.body(13, color: AppColors.neutral600),
      ),
    ),
  );
}
