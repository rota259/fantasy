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
    this.seasons = const [],
  });

  /// بونص التوقّع الصح (نفس fn_user_bonus في السيرفر).
  static const predictionBonus = 5;

  final MyPointsStatus status;
  final List<RoundEntry> entries;
  final Map<String, Player> players;
  final List<GameMatch> bonuses; // ماتشات التحدّي اللي توقّعتها صح
  final List<Season> seasons; // الأحدث الأول

  /// الجولات والبونص جوه موسم (null = كله). الجولات من الأقدم للأحدث.
  List<RoundEntry> roundsIn(Season? s) => [
    for (final e in entries)
      if (s == null || (e.window.cutoff.isAfter(s.startsAt) && !e.window.cutoff.isAfter(s.endsAt))) e,
  ]..sort((a, b) => a.window.cutoff.compareTo(b.window.cutoff));

  List<GameMatch> bonusesIn(Season? s) => [
    for (final m in bonuses)
      if (s == null || (!m.dateTime.isBefore(s.startsAt) && m.dateTime.isBefore(s.endsAt))) m,
  ];

  /// إجمالي موسم (الجولات + بونص التوقعات) — المعتمد، وفي وضع التجربة كله على طول (زي الدوري).
  int totalIn(Season? s) =>
      roundsIn(s).fold(0, (t, e) => t + (kTestMode ? e.points.total : e.finalPoints.total)) +
      bonusesIn(s).where((m) => kTestMode || m.isApproved).length * predictionBonus;

  /// المعتمد بس = نفس الإجمالي في السيرفر والترتيب.
  int get total =>
      entries.fold(0, (s, e) => s + e.finalPoints.total) + bonuses.where((m) => m.isApproved).length * predictionBonus;

  /// نقط لسه بتتأكد (ماتشات شغّالة أو مستنية اعتماد) — بتدخل الإجمالي لما تتعتمد.
  int get provisional =>
      entries.fold(0, (s, e) => s + e.points.total - e.finalPoints.total) +
      bonuses.where((m) => !m.isApproved).length * predictionBonus;

  @override
  List<Object?> get props => [status, entries, players, bonuses, seasons];
}
