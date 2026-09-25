part of 'match_ratings_cubit.dart';

class MatchRatingsState extends Equatable {
  const MatchRatingsState({this.loading = true, this.players = const [], this.ratings = const {}});

  final bool loading;
  final List<Player> players;
  final Map<String, PlayerRating> ratings; // playerId → تقييمه

  /// الأعلى تقييمًا دلوقتي (المرشّح لرجل المباراة).
  String? get leaderId {
    PlayerRating? best;
    for (final r in ratings.values) {
      if (r.avg == null || r.votes == 0) continue;
      if (best == null || r.avg! > best.avg! || (r.avg == best.avg && r.votes > best.votes)) best = r;
    }
    return best?.playerId;
  }

  MatchRatingsState copyWith({Map<String, PlayerRating>? ratings}) =>
      MatchRatingsState(loading: loading, players: players, ratings: ratings ?? this.ratings);

  MatchRatingsState withRating(PlayerRating r) => copyWith(ratings: {...ratings, r.playerId: r});

  @override
  List<Object?> get props => [loading, players, ratings];
}
