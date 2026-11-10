part of 'manager_dashboard.dart';

extension _ManagerDashboardStateSections2 on _ManagerDashboardState {
  Widget _buildBody(BuildContext context) {
    return FutureBuilder<_Stats>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(padding: EdgeInsets.all(20), child: const SkeletonList());
        }
        final s = snap.data!;
        final players = context.read<PlayersRepository>();
        ManagerMatchesScreen matches(bool finished) => ManagerMatchesScreen(
          matchesRepo: context.read<MatchesRepository>(),
          playersRepo: players,
          eventsRepo: context.read<EventsRepository>(),
          lineupRepo: context.read<LineupRepository>(),
          finished: finished,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بلاغات المراهنات: أول حاجة في اللوحة — أحمر لو فيه بلاغات مستنية
            Pressable(
              onTap: () => _open(context, const AdminBettingScreen()),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: s.betting > 0 ? AppColors.danger : AppColors.black,
                  borderRadius: AppRadius.md,
                ),
                child: Row(
                  children: [
                    Icon(Icons.block_outlined, color: AppColors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('بلاغات المراهنات', style: AppText.h(14, color: AppColors.white)),
                          Text(
                            s.betting > 0 ? '${s.betting} بلاغ مستني تحقيقك' : 'مفيش بلاغات مفتوحة',
                            style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    if (s.betting > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text('${s.betting}', style: AppText.h(13, color: AppColors.danger)),
                      ),
                    Icon(Icons.chevron_left, color: AppColors.white),
                  ],
                ),
              ),
            ),
            // كل رقم ويدجت — الضغط بيفتح القايمة بتاعته
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                _stat(
                  context,
                  s.counts.users,
                  'يوزر',
                  Icons.people_alt_outlined,
                  const ManagerUsersScreen(role: 'user'),
                ),
                _stat(
                  context,
                  s.counts.players,
                  'لاعب',
                  Icons.sports_soccer,
                  ManagerPlayersScreen(playersRepo: players),
                ),
                _stat(context, s.counts.upcoming, 'ماتش جاي', Icons.event_outlined, matches(false)),
                _stat(context, s.counts.finished, 'ماتش خلص', Icons.flag_outlined, matches(true)),
                _stat(
                  context,
                  s.managersActive,
                  'مدير منطقة',
                  Icons.badge_outlined,
                  const ManagerUsersScreen(role: 'organizer'),
                ),
                _stat(
                  context,
                  s.nextPicks,
                  'تشكيلة للجولة الجاية',
                  Icons.how_to_reg_outlined,
                  const ManagerUsersScreen(role: 'user'),
                ),
              ],
            ),
            if (s.top.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أعلى ٥ — دوس على أي حد تشوف تشكيلته',
                      style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 4),
                    for (var i = 0; i < s.top.length; i++)
                      Pressable(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _open(context, LiveRoundScreen(userId: s.top[i].id, ownerName: s.top[i].name)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                child: Text('${i + 1}', style: AppText.h(12, color: AppColors.accent400)),
                              ),
                              Expanded(
                                child: Text(s.top[i].name, style: AppText.body(12, color: AppColors.white)),
                              ),
                              Text('${s.top[i].totalPoints}', style: AppText.h(12, color: AppColors.white)),
                              Text('  ›', style: AppText.h(12, color: AppColors.white.withValues(alpha: 0.5))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
