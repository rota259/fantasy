part of 'my_points_cubit.dart';

/// ماتش + تشكيلتي فيه + الكارت + نقطي.
typedef MatchEntry = ({GameMatch match, List<Pick> picks, ChipType? chip, MatchPoints points});

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
  final List<MatchEntry> entries;
  final Map<String, Player> players;
  final List<GameMatch> bonuses; // ماتشات التحدّي اللي توقّعتها صح

  int get matchesTotal => entries.fold(0, (s, e) => s + e.points.total);
  int get total => matchesTotal + bonuses.length * predictionBonus;

  @override
  List<Object?> get props => [status, entries, players, bonuses];
}
