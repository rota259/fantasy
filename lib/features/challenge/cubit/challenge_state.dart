part of 'challenge_cubit.dart';

class ChallengeState extends Equatable {
  const ChallengeState({this.loading = true, this.match, this.mine, this.summary});

  final bool loading;
  final GameMatch? match;
  final Prediction? mine;
  final ({int total, int correct})? summary;

  bool get won => match != null && mine != null && match!.isFinished && mine!.matches(match!.scoreA, match!.scoreB);

  ChallengeState copyWith({Prediction? mine}) =>
      ChallengeState(loading: loading, match: match, mine: mine ?? this.mine, summary: summary);

  @override
  List<Object?> get props => [loading, match, mine, summary];
}
