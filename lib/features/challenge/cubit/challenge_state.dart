part of 'challenge_cubit.dart';

/// تحدّي واحد: الماتش + توقّعي + ملخص التوقعات بعد الماتش.
class ChallengeItem extends Equatable {
  const ChallengeItem({required this.match, this.mine, this.summary});

  final GameMatch match;
  final Prediction? mine;
  final ({int total, int correct})? summary;

  bool get won => mine != null && match.isFinished && mine!.matches(match.scoreA, match.scoreB);

  ChallengeItem withMine(Prediction p) => ChallengeItem(match: match, mine: p, summary: summary);

  @override
  List<Object?> get props => [match, mine, summary];
}

class ChallengeState extends Equatable {
  const ChallengeState({this.loading = true, this.items = const []});

  final bool loading;
  final List<ChallengeItem> items; // تحدّيات منطقتي (كل مدير ليه واحد في الجولة)

  @override
  List<Object?> get props => [loading, items];
}
