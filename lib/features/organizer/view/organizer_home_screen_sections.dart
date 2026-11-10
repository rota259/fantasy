part of 'organizer_home_screen.dart';

extension _OrganizerHomeScreenSections1 on OrganizerHomeScreen {
  Widget _tile(BuildContext context, IconData icon, String title, String sub, VoidCallback onTap) {
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h(16)),
                  Text(sub, style: AppText.body(11, color: AppColors.neutral700)),
                ],
              ),
            ),
            Text('›', style: AppText.body(18, color: AppColors.neutral600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    final open = WeekWindow.open();
    return Column(
      children: [
        const StatusArea(),
        FutureBuilder<Zone?>(
          future: context.read<ZonesRepository>().byId(ZoneScope.current),
          builder: (context, snap) => Masthead(title: 'منطقتي', subtitle: 'مدير منطقة · ${snap.data?.label ?? ''}'),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
                padding: const EdgeInsets.all(16),
                child: Text(
                  'الماتش لازم ينزل قبل ميعاده بساعتين على الأقل · ${open.label}',
                  style: AppText.h(13, color: AppColors.accent400),
                ),
              ),
              if (user != null) ...[
                TrustCard(userId: user.id),
                const CaptainReviews(),
                _tile(context, Icons.sports_outlined, 'ماتشاتي', 'اعمل ماتش · التشكيلة · الأحداث · النتيجة', () {
                  _push(
                    context,
                    ManagerMatchesScreen(
                      matchesRepo: context.read<MatchesRepository>(),
                      playersRepo: context.read<PlayersRepository>(),
                      eventsRepo: context.read<EventsRepository>(),
                      lineupRepo: context.read<LineupRepository>(),
                      organizerId: user.id,
                    ),
                  );
                }),
                _tile(
                  context,
                  Icons.emoji_events_outlined,
                  'البطولات',
                  'اعمل بطولة لمنطقتك — القرعة والجدول والشجرة لوحدهم',
                  () => _push(context, const TournamentsScreen()),
                ),
                _tile(
                  context,
                  Icons.play_circle_outline,
                  'هدف وتصدّي الجولة',
                  'رشّح أحلى الأهداف والتصديات من ماتشاتك وأهل منطقتك يصوّتوا',
                  () => _push(context, OrganizerAwardsScreen(organizerId: user.id)),
                ),
                _tile(
                  context,
                  Icons.sports_score_outlined,
                  'تحدّي الجولة',
                  'اختار ماتش من ماتشاتك ويوزرز منطقتك يتوقّعوا',
                  () => _push(context, ManagerChallengeScreen(organizerId: user.id)),
                ),
                _tile(
                  context,
                  Icons.location_on_outlined,
                  'احجز ملعب',
                  'الملاعب وحجوزاتك',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => Scaffold(body: PitchOverlay(onClose: () => Navigator.pop(c))),
                    ),
                  ),
                ),
                _tile(
                  context,
                  Icons.shield_outlined,
                  'فرقي ولاعيبتي',
                  'ضيف فرقك، وجوّه كل فريق ضيف لاعيبته بصورهم',
                  () => _push(context, MyTeamsScreen(userId: user.id)),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('إزاي تشتغل', style: AppText.kicker(color: AppColors.accent)),
              ),
              for (final (i, t) in OrganizerHomeScreen._steps.indexed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text('${i + 1}. $t', style: AppText.body(13)),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'حساب المدير حساب شغل: مش بيعمل تشكيلة ولا بيصوّت ولا بيظهر في الترتيب. '
                  'لو عايز تلعب فانتازي اعمل حساب تاني برقم تاني.',
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
