import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../events/data/events_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../players/data/players_repository.dart';
import '../data/lineup_repository.dart';
import 'manager_add_match_screen.dart';
import 'manager_match_screen.dart';

/// شاشة المدير: قائمة الماتشات + إنشاء ماتش جديد.
class ManagerMatchesScreen extends StatefulWidget {
  const ManagerMatchesScreen({
    super.key,
    required this.matchesRepo,
    required this.playersRepo,
    required this.eventsRepo,
    required this.lineupRepo,
  });

  final MatchesRepository matchesRepo;
  final PlayersRepository playersRepo;
  final EventsRepository eventsRepo;
  final LineupRepository lineupRepo;

  @override
  State<ManagerMatchesScreen> createState() => _ManagerMatchesScreenState();
}

class _ManagerMatchesScreenState extends State<ManagerMatchesScreen> {
  late Future<List<GameMatch>> _future = widget.matchesRepo.fetchAll();

  void _reload() => setState(() => _future = widget.matchesRepo.fetchAll());

  Future<void> _addMatch() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ManagerAddMatchScreen(matchesRepo: widget.matchesRepo)),
    );
    if (added == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'إدارة الماتشات',
            subtitle: 'MANAGER · MATCHES',
            onBack: () => Navigator.pop(context),
            trailing: GestureDetector(
              onTap: _addMatch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(border: AppBorders.white(0.5)),
                child: Text('+ ماتش', style: AppText.h(12, color: AppColors.white)),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<GameMatch>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                final matches = snap.data!;
                if (matches.isEmpty) {
                  return Center(child: Text('مفيش ماتشات — اضغط "+ ماتش"', style: AppText.body(13, color: AppColors.neutral600)));
                }
                return ListView(padding: EdgeInsets.zero, children: [for (final m in matches) _row(m)]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(GameMatch m) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManagerMatchScreen(
              match: m,
              playersRepo: widget.playersRepo,
              eventsRepo: widget.eventsRepo,
              lineupRepo: widget.lineupRepo),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(14)),
              Text('GW${m.week} · ${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)} · ${m.isFinished ? 'انتهى' : 'قادم'}',
                  style: AppText.body(10, color: AppColors.neutral700)),
            ]),
          ),
          Text('إدارة ›', style: AppText.h(12, color: AppColors.accent)),
        ]),
      ),
    );
  }
}
