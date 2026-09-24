import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../events/data/events_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../pick/data/models/pick.dart';
import '../../pick/data/picks_repository.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../match_points.dart';
import 'match_points_screen.dart';

/// ماتش + تشكيلتي فيه + نقطي.
typedef MatchEntry = ({GameMatch match, List<Pick> picks, MatchPoints points});

/// نقطك: كل ماتش عملت فيه تشكيلة وجبت فيه كام — تدوس تشوف الخماسي بالتفصيل.
class MyPointsScreen extends StatefulWidget {
  const MyPointsScreen({super.key, required this.userId});
  final String userId;

  @override
  State<MyPointsScreen> createState() => _MyPointsScreenState();
}

class _MyPointsScreenState extends State<MyPointsScreen> {
  late Future<(List<MatchEntry>, Map<String, Player>)> _future = _load();
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    // المدير سجّل حدث → النقط تتحدّث
    _sub = liveTable('events', () {
      if (mounted) setState(() { _future = _load(); });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<(List<MatchEntry>, Map<String, Player>)> _load() async {
    final picksRepo = context.read<PicksRepository>();
    final matchesRepo = context.read<MatchesRepository>();
    final eventsRepo = context.read<EventsRepository>();
    final playersRepo = context.read<PlayersRepository>();
    final byMatch = await picksRepo.fetchAllForUser(widget.userId);
    if (byMatch.isEmpty) return (const <MatchEntry>[], const <String, Player>{});
    final ids = byMatch.keys.toList();
    final matches = (await matchesRepo.fetchAll()).where((m) => ids.contains(m.id));
    final events = await eventsRepo.fetchByMatches(ids);
    final playerIds = {for (final l in byMatch.values) for (final p in l) p.playerId}.toList();
    final players = {for (final p in await playersRepo.fetchByIds(playerIds)) p.id: p};
    final list = [
      for (final m in matches)
        (
          match: m,
          picks: byMatch[m.id]!,
          points: MatchPoints.compute(
            picks: byMatch[m.id]!,
            events: events.where((e) => e.matchId == m.id).toList(),
            players: players,
          ),
        ),
    ]..sort((a, b) => b.match.dateTime.compareTo(a.match.dateTime));
    return (list, players);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const StatusArea(),
        Masthead(title: 'نقطك', subtitle: 'MY POINTS', onBack: () => Navigator.pop(context)),
        Expanded(
          child: FutureBuilder<(List<MatchEntry>, Map<String, Player>)>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)));
              }
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              final (list, players) = snap.data!;
              if (list.isEmpty) {
                return Center(
                  child: Text('لسه معملتش تشكيلة لأي ماتش', style: AppText.body(13, color: AppColors.neutral600)),
                );
              }
              final total = list.fold(0, (s, e) => s + e.points.total);
              return ListView(padding: EdgeInsets.zero, children: [
                Container(
                  color: AppColors.black,
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Expanded(
                      child: Text('إجمالي نقطك من ${list.length} ماتش',
                          style: AppText.h(13, color: AppColors.white.withValues(alpha: 0.7))),
                    ),
                    Text('$total', style: AppText.h(40, color: AppColors.white)),
                  ]),
                ),
                for (final e in list) _row(e, players),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _row(MatchEntry e, Map<String, Player> players) {
    final m = e.match;
    final status = m.isFinished
        ? 'خلص ${m.scoreText}'
        : (m.dateTime.isAfter(DateTime.now()) ? 'لسه' : 'شغّال');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchPointsScreen(entry: e, players: players)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(15)),
              Text('GW${m.week} · ${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)} · $status',
                  style: AppText.body(11, color: AppColors.neutral700)),
            ]),
          ),
          Text('${e.points.total}', style: AppText.h(24, color: AppColors.accent)),
          const SizedBox(width: 6),
          Text('›', style: AppText.body(18, color: AppColors.neutral600)),
        ]),
      ),
    );
  }
}
