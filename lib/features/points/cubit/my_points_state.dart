part of 'my_points_cubit.dart';

/// جولة + تشكيلتي فيها + الكارت + نقطي (المباشر والمعتمد).
typedef RoundEntry = ({
  WeekWindow window,
  List<Pick> picks,
  ChipType? chip,
  LineupPoints points,
  LineupPoints finalPoints,
});

enum MyPointsStatus { loading, ready, error }

class MyPointsState extends Equatable {
  const MyPointsState({
    this.status = MyPointsStatus.loading,
    this.entries = const [],
    this.players = const {},
    this.bonuses = const [],
  });

  /// بونص التوقّع الصح (نفس fn_user_bonus في السيرفر).
  static const predictionBonus = 5;

  final MyPointsStatus status;
  final List<RoundEntry> entries;
  final Map<String, Player> players;
  final List<GameMatch> bonuses; // ماتشات التحدّي اللي توقّعتها صح

  /// المعتمد بس = نفس الإجمالي في السيرفر والترتيب.
  int get total =>
      entries.fold(0, (s, e) => s + e.finalPoints.total) + bonuses.where((m) => m.isApproved).length * predictionBonus;

  /// نقط لسه بتتأكد (ماتشات شغّالة أو مستنية اعتماد) — بتدخل الإجمالي لما تتعتمد.
  int get provisional =>
      entries.fold(0, (s, e) => s + e.points.total - e.finalPoints.total) +
      bonuses.where((m) => !m.isApproved).length * predictionBonus;

  @override
  List<Object?> get props => [status, entries, players, bonuses];
}
