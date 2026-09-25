import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../manager/data/lineup_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../data/models/player_rating.dart';
import '../data/ratings_repository.dart';

part 'match_ratings_state.dart';

/// ViewModel تقييم لاعيبة ماتش (الجمهور) — ورجل المباراة بعد ما يتقفل.
class MatchRatingsCubit extends Cubit<MatchRatingsState> {
  MatchRatingsCubit(this._ratings, this._lineups, this._players, this.match, this.userId)
    : super(const MatchRatingsState());

  final RatingsRepository _ratings;
  final LineupRepository _lineups;
  final PlayersRepository _players;
  final GameMatch match;
  final String userId;

  Future<void> load() async {
    try {
      final (lineup, ratings) = await (_lineups.fetchForMatch(match.id), _ratings.summary(match.id)).wait;
      final players = await _players.fetchByIds(lineup.map((l) => l.playerId).toList());
      emit(
        MatchRatingsState(
          loading: false,
          players: players..sort((a, b) => a.team.compareTo(b.team)),
          ratings: {for (final r in ratings) r.playerId: r},
        ),
      );
    } catch (_) {
      emit(const MatchRatingsState(loading: false));
    }
  }

  /// بيرجّع رسالة خطأ أو null.
  Future<String?> rate(String playerId, int value) async {
    if (!match.ratingOpen) return 'التقييم اتقفل';
    final old = state.ratings[playerId];
    // تحديث فوري في الشاشة، وبعدين نجيب المتوسط الحقيقي
    emit(state.withRating(PlayerRating(playerId: playerId, avg: old?.avg, votes: old?.votes ?? 0, mine: value)));
    try {
      await _ratings.rate(match.id, playerId, userId, value);
      final fresh = await _ratings.summary(match.id);
      if (!isClosed) emit(state.copyWith(ratings: {for (final r in fresh) r.playerId: r}));
      return null;
    } catch (e) {
      if (old != null && !isClosed) emit(state.withRating(old));
      return dbMessage(e, fallback: 'تعذّر حفظ التقييم');
    }
  }
}
