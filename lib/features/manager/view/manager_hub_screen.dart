import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../events/data/events_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../pitch/view/venue_requests_screen.dart';
import '../../players/data/players_repository.dart';
import '../data/lineup_repository.dart';
import '../widgets/manager_dashboard.dart';
import 'manager_availability_screen.dart';
import 'manager_awards_screen.dart';
import 'manager_broadcast_screen.dart';
import 'manager_challenge_screen.dart';
import 'manager_claims_screen.dart';
import 'manager_leagues_screen.dart';
import 'manager_matches_screen.dart';
import 'manager_players_screen.dart';
import 'manager_seasons_screen.dart';
import 'manager_users_screen.dart';
import 'manager_venues_screen.dart';

/// لوحة المدير: إحصائيات سريعة + كل أدوات الإدارة.
class ManagerHubScreen extends StatelessWidget {
  const ManagerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final players = context.read<PlayersRepository>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'لوحة المدير', subtitle: 'MANAGER', onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const ManagerDashboard(),
                _group('الماتشات واللاعيبة'),
                _tile(
                  context,
                  Icons.event_note_outlined,
                  'إدارة الماتشات',
                  'تشكيلات · أحداث · نتيجة · مين نزّل',
                  ManagerMatchesScreen(
                    matchesRepo: context.read<MatchesRepository>(),
                    playersRepo: players,
                    eventsRepo: context.read<EventsRepository>(),
                    lineupRepo: context.read<LineupRepository>(),
                  ),
                ),
                _tile(
                  context,
                  Icons.groups_outlined,
                  'إدارة اللاعيبة',
                  'ضيف وعدّل واحذف',
                  ManagerPlayersScreen(playersRepo: players),
                ),
                _tile(
                  context,
                  Icons.healing_outlined,
                  'حالة اللاعيبة',
                  'جاهز / مصاب / موقوف + السبب',
                  ManagerAvailabilityScreen(playersRepo: players),
                ),
                _tile(
                  context,
                  Icons.verified_outlined,
                  'توثيق اللاعيبة',
                  'طلبات "ده أنا" — وافق أو ارفض',
                  const ManagerClaimsScreen(),
                ),
                _group('الموسم والمسابقات'),
                _tile(
                  context,
                  Icons.date_range_outlined,
                  'الموسم',
                  'البداية + نص الموسم + النهاية (للكروت)',
                  const ManagerSeasonsScreen(),
                ),
                _tile(
                  context,
                  Icons.sports_score_outlined,
                  'تحدّي الجولة',
                  'اختار ماتش (أو عشوائي) — التوقّع الصح +٥',
                  const ManagerChallengeScreen(),
                ),
                _tile(
                  context,
                  Icons.play_circle_outline,
                  'هدف وتصدّي الجولة',
                  'مرشّحين بفيديو + نتايج + تصويت الموسم',
                  const ManagerAwardsScreen(),
                ),
                _group('المجتمع'),
                _tile(
                  context,
                  Icons.campaign_outlined,
                  'إشعار للكل',
                  'ابعت أي رسالة لكل اليوزرز',
                  const ManagerBroadcastScreen(),
                ),
                _tile(
                  context,
                  Icons.leaderboard_outlined,
                  'الدوريات',
                  'كل دوريات اليوزرز — احذف المخالف',
                  const ManagerLeaguesScreen(),
                ),
                _tile(
                  context,
                  Icons.manage_accounts_outlined,
                  'المستخدمين',
                  'خلّي حد مدير أو شيل الإدارة',
                  const ManagerUsersScreen(),
                ),
                _tile(
                  context,
                  Icons.location_on_outlined,
                  'الملاعب',
                  'كل الملاعب (بتاعتك وبتاعة اليوزرز) + صاحبها',
                  const ManagerVenuesScreen(),
                ),
                _tile(
                  context,
                  Icons.event_available_outlined,
                  'طلبات الحجز',
                  'كل الحجوزات — أكّد أو ارفض',
                  const VenueRequestsScreen(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
    child: Text(t, style: AppText.kicker(color: AppColors.accent)),
  );

  Widget _tile(BuildContext context, IconData icon, String title, String sub, Widget screen) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h(15)),
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
}
