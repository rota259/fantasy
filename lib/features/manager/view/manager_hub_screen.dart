import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../events/data/events_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../players/data/players_repository.dart';
import '../data/lineup_repository.dart';
import 'manager_matches_screen.dart';
import 'manager_players_screen.dart';

/// لوحة المدير الرئيسية: إدارة اللاعيبة والماتشات.
class ManagerHubScreen extends StatelessWidget {
  const ManagerHubScreen({
    super.key,
    required this.playersRepo,
    required this.matchesRepo,
    required this.eventsRepo,
    required this.lineupRepo,
  });

  final PlayersRepository playersRepo;
  final MatchesRepository matchesRepo;
  final EventsRepository eventsRepo;
  final LineupRepository lineupRepo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'لوحة المدير',
            subtitle: 'MANAGER',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _tile(context, Icons.groups_outlined, 'إدارة اللاعيبة', 'ضيف لاعيبة بالمراكز والأسعار',
                    ManagerPlayersScreen(playersRepo: playersRepo)),
                _tile(context, Icons.event_note_outlined, 'إدارة الماتشات', 'نزّل التشكيلات وسجّل الأحداث',
                    ManagerMatchesScreen(
                        matchesRepo: matchesRepo,
                        playersRepo: playersRepo,
                        eventsRepo: eventsRepo,
                        lineupRepo: lineupRepo)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String sub, Widget screen) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
        child: Row(children: [
          Icon(icon, size: 22, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.h(15)),
              Text(sub, style: AppText.body(11, color: AppColors.neutral700)),
            ]),
          ),
          Text('›', style: AppText.body(18, color: AppColors.neutral600)),
        ]),
      ),
    );
  }
}
