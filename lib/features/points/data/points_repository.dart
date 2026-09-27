import 'player_round_points.dart';

/// عقد نقط اللاعيبة (بتتحسب في السيرفر بس — fn_pmp).
abstract interface class PointsRepository {
  /// نقط لاعيبة معيّنين في جولة (بنهايتها): لاعب → نقطه وتفصيلها.
  Future<Map<String, PlayerRoundPoints>> roundPlayerPoints(DateTime roundEnd, List<String> playerIds);
}
