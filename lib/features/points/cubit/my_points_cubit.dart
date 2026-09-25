import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../chips/data/chip_type.dart';
import '../../chips/data/chips_repository.dart';
import '../../events/data/events_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../pick/data/models/pick.dart';
import '../../pick/data/picks_repository.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../match_points.dart';
import '../../../core/utils/perf.dart';

part 'my_points_state.dart';

/// ViewModel "نقطك": كل ماتش عملت فيه تشكيلة ونقطه (بالكروت) + بونص التوقعات.
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
      final (byMatch, won, chips) = await (
        _picks.fetchAllForUser(userId),
        _challenge.wonMatches(userId),
        _chips.usedByMatch(userId),
      ).wait;
      if (byMatch.isEmpty) {
        if (!isClosed) emit(MyPointsState(status: MyPointsStatus.ready, bonuses: won));
        return;
      }
      final ids = byMatch.keys.toList();
      final playerIds = {
        for (final l in byMatch.values)
          for (final p in l) p.playerId,
      }.toList();
      final (matches, events, playerList) = await (
        _matches.fetchByIds(ids),
        _events.fetchByMatches(ids),
        _players.fetchByIds(playerIds),
      ).wait;
      final players = {for (final p in playerList) p.id: p};
      final entries = <MatchEntry>[
        for (final m in matches)
          (
            match: m,
            picks: byMatch[m.id]!,
            chip: chips[m.id],
            points: MatchPoints.compute(
              picks: byMatch[m.id]!,
              events: events.where((e) => e.matchId == m.id).toList(),
              players: players,
              chip: chips[m.id],
            ),
          ),
      ]..sort((a, b) => b.match.dateTime.compareTo(a.match.dateTime));
      if (!isClosed) {
        emit(MyPointsState(status: MyPointsStatus.ready, entries: entries, players: players, bonuses: won));
      }
    } catch (_) {
      if (!isClosed && state.status == MyPointsStatus.loading) {
        emit(const MyPointsState(status: MyPointsStatus.error));
      }
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
