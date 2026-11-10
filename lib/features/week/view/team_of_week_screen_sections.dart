part of 'team_of_week_screen.dart';

extension _ViewSections1 on _View {
  Widget _body(BuildContext context, TeamOfWeekState s) {
    if (s.isLoading) return const SkeletonList();
    final cubit = context.read<TeamOfWeekCubit>();
    if (!s.isPublished) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              s.isCurrent
                  ? 'لسه مفيش ماتش اتعتمد في الجولة دي\nأول ما نتيجة ماتش تتعتمد، أعلى ٥ لحد دلوقتي هيظهروا هنا.'
                  : 'الجولة دي مكانش فيها ماتشات معتمدة في منطقتك.',
              textAlign: TextAlign.center,
              style: AppText.body(13, color: AppColors.neutral700),
            ),
          ),
          if (s.tie != null && s.tied.isNotEmpty)
            TotwTieSection(
              tied: s.tied,
              slots: s.slots,
              poll: s.tie,
              onVote: (id) async {
                final messenger = ScaffoldMessenger.of(context);
                final err = await cubit.voteTie(id);
                if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
              },
            ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (s.isCurrent) _liveNote(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Pressable(
            onTap: () => _View._reveal(context, s),
            child: GoldShine(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text('اكشف التشكيلة وشيّرها', style: AppText.h(14, color: const Color(0xFF3A2600))),
              ),
            ),
          ),
        ),
        TotwPitch(spots: s.spots, onTap: (p) => _open(context, p, s.window)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Text(s.isCurrent ? 'الترتيب لحد دلوقتي' : 'ترتيب الجولة', style: AppText.h(15)),
        ),
        for (var i = 0; i < s.ranking.length && i < 15; i++)
          FadeSlideIn(
            index: i,
            child: Pressable(
              behavior: HitTestBehavior.opaque,
              onTap: () => _open(context, s.ranking[i], s.window),
              child: _row(i + 1, s.ranking[i], s.spots.any((x) => x?.id == s.ranking[i].id)),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// الضغط على لاعب = عمل إيه في الجولة (كل ماتش · ضد مين · نقطه).
  void _open(BuildContext context, WeekPlayer p, WeekWindow w) =>
      showPlayerMatchesSheet(context, playerId: p.id, name: p.name, team: p.team, window: w);

  /// صف في الترتيب: اللي دخلوا التشكيلة بدهب بيلمع، والباقي بالأخضر.
  Widget _row(int rank, WeekPlayer p, bool inTeam) => Container(
    margin: AppDecor.tileMargin,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: inTeam
        ? AppDecor.tile.copyWith(border: Border.all(color: const Color(0xFFC9971C), width: 1.4))
        : AppDecor.tile,
    child: Row(
      children: [
        SizedBox(
          width: 24,
          child: Text('$rank', style: AppText.h(13, color: PitchColors.grass)),
        ),
        if (inTeam)
          GoldAvatar(player: p, size: 32)
        else
          Jersey(label: p.initials, size: 34, phase: (p.id.hashCode % 100) / 100),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: AppText.h(14)),
              Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
            ],
          ),
        ),
        Text('${p.points}', style: AppText.h(20, color: inTeam ? AppColors.gold : null)),
      ],
    ),
  );
}
