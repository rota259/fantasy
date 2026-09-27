import '../chips/data/chip_type.dart';
import '../pick/data/models/pick.dart';
import 'data/player_round_points.dart';

/// نقاط لاعب واحد في تشكيلة اليوزر في جولة.
class PickPoints {
  const PickPoints({
    required this.pick,
    required this.base,
    required this.multiplier,
    this.items = const [],
    this.counted = true,
  });

  final Pick pick;
  final int base; // نقطه في كل ماتشات الجولة (من السيرفر)
  final int multiplier; // 2 = الكابتن (أو البديل لو الكابتن ملعبش) · 3 مع كارت كابتن ×٣
  final List<ScoreItem> items; // التفصيل (جول ×٢، هاتريك، تصديات...)
  final bool counted; // الاحتياطي مش بيتحسب (إلا مع كارت الاحتياطي يتحسب)

  int get total => counted ? base * multiplier : 0;
}

/// نقاط تشكيلة يوزر في جولة — **نفس** fn_round_points_bulk في السيرفر.
/// نقط كل لاعب نفسها جاية جاهزة من السيرفر (قواعد التسجيل هناك بس)، وهنا المضاعفات:
///   • الأساسيين بس بيتحسبوا (مع كارت "الاحتياطي يتحسب" الكل).
///   • الكابتن ×2 لو لعب في الجولة، ولو ملعبش → الكابتن البديل ×2.
///   • كارت كابتن ×٣ → المضاعف ×3 · كارت الدبل → المجموع كله ×2.
class LineupPoints {
  LineupPoints._(this.rows, this.chip);

  final List<PickPoints> rows;
  final ChipType? chip;

  int get subtotal => rows.fold(0, (s, r) => s + r.total);
  int get total => chip == ChipType.doubleUp ? subtotal * 2 : subtotal;
  PickPoints? of(String playerId) {
    for (final r in rows) {
      if (r.pick.playerId == playerId) return r;
    }
    return null;
  }

  /// [approvedOnly]: النقط المعتمدة بس (اللي بتدخل الإجمالي).
  factory LineupPoints.compute({
    required List<Pick> picks,
    required Map<String, PlayerRoundPoints> points,
    bool approvedOnly = false,
    ChipType? chip,
  }) {
    int baseOf(String id) => approvedOnly ? (points[id]?.finalPoints ?? 0) : (points[id]?.points ?? 0);
    bool playedOf(String id) => approvedOnly ? (points[id]?.playedFinal ?? false) : (points[id]?.played ?? false);
    final captainPlayed = picks.any((p) => p.isCaptain && playedOf(p.playerId));
    final boosted = chip == ChipType.triple ? 3 : 2;
    return LineupPoints._([
      for (final p in picks)
        PickPoints(
          pick: p,
          base: baseOf(p.playerId),
          multiplier: ((p.isCaptain && captainPlayed) || (p.isVice && !captainPlayed)) ? boosted : 1,
          items: points[p.playerId]?.items ?? const [],
          counted: p.status == 'starting' || chip == ChipType.benchBoost,
        ),
    ], chip);
  }
}
