part of 'challenge_cubit.dart';

/// تحدّي واحد: الماتش + توقّعي لفرق الأهداف + باقي الأنواع وإجاباتي ([extras]) + ملخص التوقعات بعد الماتش.
class ChallengeItem extends Equatable {
  const ChallengeItem({required this.match, this.mine, this.summary, this.extras = const ChallengeExtras()});

  final GameMatch match;
  final Prediction? mine;
  final ({int total, int correct})? summary;
  final ChallengeExtras extras;

  bool get won => mine != null && match.isFinished && mine!.matches(match.scoreA, match.scoreB);

  ChallengeItem withMine(Prediction p) => ChallengeItem(match: match, mine: p, summary: summary, extras: extras);
  ChallengeItem withAnswers(ChallengeAnswers a) =>
      ChallengeItem(match: match, mine: mine, summary: summary, extras: extras.withMine(a));

  @override
  List<Object?> get props => [match, mine, summary, extras];
}

class ChallengeState extends Equatable {
  const ChallengeState({this.loading = true, this.items = const [], this.streak = 0});

  final bool loading;
  final int streak; // كام مرة ورا بعض جبت فرق الأهداف صح (الجاية: +٥ ← +٧ ← +١٠)
  final List<ChallengeItem> items; // تحدّيات منطقتي (كل مدير ليه واحد في الجولة)

  @override
  List<Object?> get props => [loading, items, streak];
}
