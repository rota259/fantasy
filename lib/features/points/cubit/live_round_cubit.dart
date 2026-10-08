import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live_hub.dart';
import '../../chips/data/chips_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/match_live.dart';
import '../../pick/data/picks_repository.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../week/data/week_window.dart';
import '../data/points_repository.dart';
import '../lineup_points.dart';
import '../play_status.dart';
import 'my_points_cubit.dart';

part 'live_round_state.dart';

/// ViewModel الجولة اللي بتتلعب: تشكيلتي فيها ونقط كل لاعب لحد دلوقتي + مين لعب ومين لسه.
/// بيتحدّث لوحده مع كل حدث أو ماتش يخلص.
class LiveRoundCubit extends Cubit<LiveRoundState> {
  LiveRoundCubit({
    required this.userId,
    required PicksRepository picks,
    required ChipsRepository chips,
    required PointsRepository points,
    required PlayersRepository players,
    required MatchesRepository matches,
  }) : _picks = picks,
       _chips = chips,
       _points = points,
       _players = players,
       _matches = matches,
       super(LiveRoundState(window: WeekWindow.live()));

  final String userId;
  final PicksRepository _picks;
  final ChipsRepository _chips;
  final PointsRepository _points;
  final PlayersRepository _players;
  final MatchesRepository _matches;
  final _subs = <StreamSubscription<void>>[];
  Timer? _clock;

  Future<void> load() async {
    await _fetch();
    if (_subs.isEmpty) {
      _subs
        ..add(LiveHub.on('events', _fetch, debounce: const Duration(seconds: 3)))
        ..add(LiveHub.on('matches', _fetch, debounce: const Duration(seconds: 3)));
    }
    _clock ??= Timer.periodic(const Duration(minutes: 1), (_) => _fetch()); // ماتش بدأ ميعاده
  }

  Future<void> _fetch() async {
    final w = state.window;
    try {
      final (picks, chips, matches) = await (
        _picks.fetchRound(userId, w.cutoff),
        _chips.usedByRound(userId),
        _matches.fetchInWindow(w.start, w.cutoff),
      ).wait;
      if (picks.isEmpty) {
        if (!isClosed) emit(LiveRoundState(window: w, status: LiveRoundStatus.ready));
        return;
      }
      final ids = [for (final p in picks) p.playerId];
      final (pts, players) = await (_points.roundPlayerPoints(w.cutoff, ids), _players.fetchByIds(ids)).wait;
      final byId = {for (final p in players) p.id: p};
      final chip = chips[w.cutoff];
      final RoundEntry entry = (
        window: w,
        picks: picks,
        chip: chip,
        points: LineupPoints.compute(picks: picks, points: pts, chip: chip),
        finalPoints: LineupPoints.compute(picks: picks, points: pts, chip: chip, approvedOnly: true),
      );
      if (isClosed) return;
      emit(
        LiveRoundState(
          window: w,
          status: LiveRoundStatus.ready,
          entry: entry,
          players: byId,
          liveTeams: MatchLive.liveTeams(matches),
          statusFor: {
            for (final id in ids)
              if (byId[id] != null) id: playStatus(byId[id]!.team, matches, played: pts[id]?.played ?? false),
          },
        ),
      );
    } catch (_) {
      if (!isClosed && state.status == LiveRoundStatus.loading) {
        emit(LiveRoundState(window: w, status: LiveRoundStatus.error));
      }
    }
  }

  @override
  Future<void> close() {
    _clock?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    return super.close();
  }
}
