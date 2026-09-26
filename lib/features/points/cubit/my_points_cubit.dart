import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../chips/data/chip_type.dart';
import '../../chips/data/chips_repository.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/models/match_event.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../pick/data/models/pick.dart';
import '../../pick/data/picks_repository.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../week/data/week_window.dart';
import '../lineup_points.dart';
import '../../../core/utils/perf.dart';

part 'my_points_state.dart';

/// ViewModel "نقطك": كل جولة عملت فيها تشكيلة ونقطها (بالكروت) + بونص التوقعات.
/// بيتحدّث لوحده مع كل حدث بيتسجّل.
class MyPointsCubit extends Cubit<MyPointsState> {
  MyPointsCubit({
    required this.userId,
    required PicksRepository picks,
    required MatchesRepository matches,
    required EventsRepository events,
    required PlayersRepository players,
    required ChipsRepository chips,
    required ChallengeRepository challenge,
  }) : _picks = picks,
       _matches = matches,
       _events = events,
       _players = players,
       _chips = chips,
       _challenge = challenge,
       super(const MyPointsState());

  final String userId;
  final PicksRepository _picks;
  final MatchesRepository _matches;
  final EventsRepository _events;
  final PlayersRepository _players;
  final ChipsRepository _chips;
  final ChallengeRepository _challenge;
  StreamSubscription<void>? _sub;

  Future<void> load() async {
    await timed('my points', _fetch);
    _sub ??= liveTable('events', _fetch);
  }

  Future<void> _fetch() async {
    try {
      final (byRound, won, chips) = await (
        _picks.fetchAllRounds(userId),
        _challenge.wonMatches(userId),
        _chips.usedByRound(userId),
      ).wait;
      if (byRound.isEmpty) {
        if (!isClosed) emit(MyPointsState(status: MyPointsStatus.ready, bonuses: won));
        return;
      }
      final playerIds = {
        for (final l in byRound.values)
          for (final p in l) p.playerId,
      }.toList();
      final (events, playerList) = await (_events.fetchForPlayers(playerIds), _players.fetchByIds(playerIds)).wait;
      final matches = {
        for (final m in await _matches.fetchByIds(events.map((e) => e.matchId).toSet().toList())) m.id: m,
      };
      final players = {for (final p in playerList) p.id: p};
      final entries = <RoundEntry>[
        for (final MapEntry(key: end, value: picks) in byRound.entries)
          _entry(WeekWindow(end), picks, chips[end], events, matches, players),
      ]..sort((a, b) => b.window.cutoff.compareTo(a.window.cutoff));
      if (!isClosed) {
        emit(MyPointsState(status: MyPointsStatus.ready, entries: entries, players: players, bonuses: won));
      }
    } catch (_) {
      if (!isClosed && state.status == MyPointsStatus.loading) {
        emit(const MyPointsState(status: MyPointsStatus.error));
      }
    }
  }

  /// نقط جولة: المباشر (كل الماتشات غير الملغية) والمعتمد (الماتشات المعتمدة بس) — زي السيرفر.
  static RoundEntry _entry(
    WeekWindow w,
    List<Pick> picks,
    ChipType? chip,
    List<MatchEvent> events,
    Map<String, GameMatch> matches,
    Map<String, Player> players,
  ) {
    final inRound = [
      for (final e in events)
        if (matches[e.matchId] case final m? when w.contains(m.dateTime) && !m.isVoid) e,
    ];
    LineupPoints calc(List<MatchEvent> evs) =>
        LineupPoints.compute(picks: picks, events: evs, players: players, chip: chip);
    return (
      window: w,
      picks: picks,
      chip: chip,
      points: calc(inRound),
      finalPoints: calc([
        for (final e in inRound)
          if (matches[e.matchId]!.isApproved) e,
      ]),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
