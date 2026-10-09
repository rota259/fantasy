import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/data/models/app_user.dart';
import '../../week/data/week_window.dart';
import '../data/admin_repository.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/motion.dart';
import '../../events/data/events_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../players/data/players_repository.dart';
import '../../points/view/live_round_screen.dart';
import '../data/lineup_repository.dart';
import '../view/manager_matches_screen.dart';
import '../view/manager_players_screen.dart';
import '../view/manager_users_screen.dart';

typedef _Stats = ({AdminCounts counts, List<AppUser> top, int nextPicks, int managersActive});

/// (أدمن) أرقام سريعة من السيرفر — كل رقم كارت بيفتح القايمة بتاعته (من غير ما نحمّل كل اليوزرز واللاعيبة): المستخدمين، اللاعيبة، الماتشات،
/// تشكيلات الجولة الجاية، وأعلى ٥.
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  late final Future<_Stats> _future = _load();

  Future<_Stats> _load() async {
    final admin = context.read<AdminRepository>();
    final (counts, top, picks) = await (
      admin.counts(),
      admin.fetchUsers(role: 'user', limit: 5),
      admin.roundPickerCount(WeekWindow.open().cutoff),
    ).wait;
    return (counts: counts, top: top, nextPicks: picks, managersActive: counts.managers);
  }

  @override
  Widget build(BuildContext context) {
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

  void _open(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  /// كارت رقم: أيقونة + الرقم + الاسم — بيتضغط.
  Widget _stat(BuildContext context, int value, String label, IconData icon, Widget screen) => Pressable(
    onTap: () => _open(context, screen),
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: AppDecor.tile,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.accent100, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUp(value: value, style: AppText.h(22, height: 1)),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, size: 18, color: AppColors.neutral500),
        ],
      ),
    ),
  );
}
