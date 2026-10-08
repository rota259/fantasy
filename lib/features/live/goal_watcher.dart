import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/supabase/live_hub.dart';
import '../events/data/events_repository.dart';
import '../pick/data/picks_repository.dart';
import '../players/data/models/player.dart';
import '../players/data/players_repository.dart';
import '../points/points_engine.dart';
import '../week/data/week_window.dart';
import 'goal_celebration.dart';

/// بيسمع الأحداث لايف: أي جول جديد للاعب في تشكيلتي (الجولة اللي بتتلعب) وأنا فاتح الأبلكيشن → لحظة الجول.
/// أول تحميل بيحفظ الأهداف القديمة من غير احتفال (عشان ميحتفلش بجول من إمبارح).
class GoalWatcher extends StatefulWidget {
  const GoalWatcher({super.key, required this.userId, required this.child});
  final String userId;
  final Widget child;

  @override
  State<GoalWatcher> createState() => _GoalWatcherState();
}

class _GoalWatcherState extends State<GoalWatcher> {
  final _seen = <String>{};
  bool _primed = false;
  bool _busy = false;
  StreamSubscription<void>? _sub;
  Future<void> _queue = Future.value(); // احتفال ورا التاني

  @override
  void initState() {
    super.initState();
    _check();
    _sub = LiveHub.on('events', _check, debounce: const Duration(milliseconds: 400), jitter: Duration.zero);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_busy || !mounted) return;
    _busy = true;
    try {
      final picks = await context.read<PicksRepository>().fetchRound(widget.userId, WeekWindow.live().cutoff);
      if (picks.isEmpty || !mounted) return;
      final ids = [for (final p in picks) p.playerId];
      final goals = (await context.read<EventsRepository>().fetchForPlayers(ids)).where((e) => e.type == 'goal');
      if (!_primed) {
        _seen.addAll(goals.map((e) => e.id));
        _primed = true;
        return;
      }
      final fresh = [
        for (final e in goals)
          if (_seen.add(e.id)) e,
      ];
      if (fresh.isEmpty || !mounted) return;
      final players = {
        for (final p in await context.read<PlayersRepository>().fetchByIds(
          {for (final e in fresh) e.playerId}.toList(),
        ))
          p.id: p,
      };
      final captain = picks.where((p) => p.isCaptain).firstOrNull?.playerId;
      for (final e in fresh) {
        final p = players[e.playerId];
        if (p != null) _enqueue(p, captain == p.id);
      }
    } catch (_) {
      // الاحتفال إضافة — لو فشل التطبيق يكمّل عادي
    } finally {
      _busy = false;
    }
  }

  void _enqueue(Player p, bool captain) {
    _queue = _queue.then((_) async {
      if (!mounted) return;
      final pts = PointsEngine.eventPoints('goal', p.position) * (captain ? 2 : 1);
      await showGoalCelebration(context, player: p, points: pts, captain: captain);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
