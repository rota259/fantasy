import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live_hub.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/models/match_event.dart';
import '../../manager/data/lineup_repository.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../data/matches_repository.dart';
import '../data/models/game_match.dart';

part 'match_center_state.dart';

/// ViewModel صفحة الماتش (لأي يوزر): النتيجة + الأحداث + التشكيلتين — بتتحدّث لايف مع كل حدث.
class MatchCenterCubit extends Cubit<MatchCenterState> {
  MatchCenterCubit(this._matches, this._events, this._lineups, this._players, GameMatch match)
    : super(MatchCenterState(match: match));

  final MatchesRepository _matches;
  final EventsRepository _events;
  final LineupRepository _lineups;
  final PlayersRepository _players;
  final _subs = <StreamSubscription<void>>[];

  Future<void> load() async {
    await _fetch();
    if (_subs.isEmpty) {
      const fast = Duration(milliseconds: 300);
      _subs
        ..add(LiveHub.on('events', _fetch, debounce: fast, jitter: const Duration(milliseconds: 700)))
        ..add(LiveHub.on('matches', _fetch, debounce: fast, jitter: const Duration(milliseconds: 700)));
    }
  }

  Future<void> _fetch() async {
    final id = state.match.id;
    try {
      final (fresh, events, lineup, players) = await (
        _matches.fetchByIds([id]),
        _events.fetchByMatch(id),
        _lineups.fetchForMatch(id),
        _players.fetchByTeams(state.match.teams),
      ).wait;
      if (isClosed) return;
      emit(
        MatchCenterState(
          match: fresh.isEmpty ? state.match : fresh.first,
          loading: false,
          events: events,
          lineup: {for (final l in lineup) l.playerId: l.status},
          players: {for (final p in players) p.id: p},
        ),
      );
    } catch (_) {
      if (!isClosed && state.loading) emit(MatchCenterState(match: state.match, loading: false));
    }
  }

  @override
  Future<void> close() {
    for (final s in _subs) {
      s.cancel();
    }
    return super.close();
  }
}
