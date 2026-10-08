import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_mode.dart';
import '../../../core/supabase/live_hub.dart';
import '../../../core/utils/perf.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../chips/data/chip_type.dart';
import '../../chips/data/chips_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../pick/data/models/pick.dart';
import '../../pick/data/picks_repository.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../seasons/data/season.dart';
import '../../seasons/data/seasons_repository.dart';
import '../../week/data/week_window.dart';
import '../data/player_round_points.dart';
import '../data/points_repository.dart';
import '../lineup_points.dart';

part 'my_points_state.dart';

/// ViewModel "نقطك": كل جولة عملت فيها تشكيلة ونقطها (بالكروت) + بونص التوقعات + المواسم (للفلترة).
/// نقط كل لاعب جاية جاهزة من السيرفر (القواعد هناك بس)، وبتتحدّث مع كل حدث في منطقتي.
class MyPointsCubit extends Cubit<MyPointsState> {
  MyPointsCubit({
    required this.userId,
    required PicksRepository picks,
    required PlayersRepository players,
    required ChipsRepository chips,
    required ChallengeRepository challenge,
    required PointsRepository points,
    required SeasonsRepository seasons,
  }) : _picks = picks,
       _seasons = seasons,
       _players = players,
       _chips = chips,
       _challenge = challenge,
       _points = points,
       super(const MyPointsState());

  final String userId;
  final PicksRepository _picks;
  final PlayersRepository _players;
  final ChipsRepository _chips;
  final ChallengeRepository _challenge;
  final PointsRepository _points;
  final SeasonsRepository _seasons;
  StreamSubscription<void>? _sub;

  Future<void> load() async {
    await timed('my points', _fetch);
    _sub ??= LiveHub.on('events', _fetch, debounce: const Duration(seconds: 3));
  }

  Future<void> _fetch() async {
    try {
      final (byRound, won, chips, seasons) = await (
        _picks.fetchAllRounds(userId),
        _challenge.wonMatches(userId),
        _chips.usedByRound(userId),
        _seasons.fetchAll().catchError((_) => const <Season>[]),
      ).wait;
      final playerIds = {
        for (final l in byRound.values)
          for (final p in l) p.playerId,
      }.toList();
      final rounds = byRound.keys.toList();
      final (playerList, perRound) = await (
        _players.fetchByIds(playerIds),
        Future.wait([
          for (final r in rounds) _points.roundPlayerPoints(r, byRound[r]!.map((p) => p.playerId).toList()),
        ]),
      ).wait;
      final entries = <RoundEntry>[
        for (var i = 0; i < rounds.length; i++)
          _entry(WeekWindow(rounds[i]), byRound[rounds[i]]!, chips[rounds[i]], perRound[i]),
      ]..sort((a, b) => b.window.cutoff.compareTo(a.window.cutoff));
      if (!isClosed) {
        emit(
          MyPointsState(
            status: MyPointsStatus.ready,
            entries: entries,
            players: {for (final p in playerList) p.id: p},
            bonuses: won,
            seasons: seasons,
          ),
        );
      }
    } catch (_) {
      if (!isClosed && state.status == MyPointsStatus.loading) {
        emit(const MyPointsState(status: MyPointsStatus.error));
      }
    }
  }

  /// نقط جولة: المباشر (كل الماتشات غير الملغية) والمعتمد (الماتشات المعتمدة بس) — زي السيرفر.
  static RoundEntry _entry(WeekWindow w, List<Pick> picks, ChipType? chip, Map<String, PlayerRoundPoints> pts) => (
    window: w,
    picks: picks,
    chip: chip,
    points: LineupPoints.compute(picks: picks, points: pts, chip: chip),
    finalPoints: LineupPoints.compute(picks: picks, points: pts, chip: chip, approvedOnly: true),
  );

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
