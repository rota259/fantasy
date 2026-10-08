import 'player_match_line.dart';
import 'player_round_points.dart';
import 'round_recap.dart';

/// عقد نقط اللاعيبة (بتتحسب في السيرفر بس — fn_pmp).
abstract interface class PointsRepository {
  /// نقط لاعيبة معيّنين في جولة (بنهايتها): لاعب → نقطه وتفصيلها.
  Future<Map<String, PlayerRoundPoints>> roundPlayerPoints(DateTime roundEnd, List<String> playerIds);

  /// لاعب عمل إيه في جولة: كل ماتش (ضد مين · النتيجة · نقطه · التفصيل).
  Future<List<PlayerMatchLine>> playerRoundMatches(String playerId, DateTime roundEnd);

  /// ملخص جولتي (نقط · ترتيب قبل وبعد · أحسن اختيار · الكابتن).
  Future<RoundRecap> roundRecap(DateTime roundEnd);
}
