import '../chips/data/chip_type.dart';
import '../events/data/models/match_event.dart';
import '../pick/data/models/pick.dart';
import '../players/data/models/player.dart';
import 'points_engine.dart';

/// نقاط لاعب واحد في تشكيلة اليوزر في جولة.
class PickPoints {
  const PickPoints({
    required this.pick,
    required this.base,
    required this.multiplier,
    required this.events,
    this.counted = true,
  });

  final Pick pick;
  final int base; // نقاطه من أحداثه في كل ماتشات الجولة
  final int multiplier; // 2 = الكابتن (أو النائب لو الكابتن ملعبش) · 3 مع كارت كابتن ×٣
  final List<MatchEvent> events;
  final bool counted; // الاحتياطي مش بيتحسب (إلا مع كارت الاحتياطي يتحسب)

  int get total => counted ? base * multiplier : 0;
}

/// نقاط تشكيلة يوزر في جولة — **نفس** قاعدة الداتابيز (fn_user_round_points):
///   • الأساسيين بس بيتحسبوا (مع كارت "الاحتياطي يتحسب" الكل).
///   • الكابتن ×2 لو ليه أي حدث في الجولة (لعب)، ولو ملعبش → الكابتن البديل ×2.
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

  factory LineupPoints.compute({
    required List<Pick> picks,
    required List<MatchEvent> events, // أحداث ماتشات الجولة دي بس
    required Map<String, Player> players,
    ChipType? chip,
  }) {
    List<MatchEvent> eventsOf(String id) => events.where((e) => e.playerId == id).toList();
    final captainPlayed = picks.any((p) => p.isCaptain && eventsOf(p.playerId).isNotEmpty);
    final boosted = chip == ChipType.triple ? 3 : 2;

    final rows = <PickPoints>[];
    for (final p in picks) {
      final evs = eventsOf(p.playerId);
      final pos = players[p.playerId]?.position ?? '';
      final base = evs.fold(0, (s, e) => s + PointsEngine.eventPoints(e.type, pos));
      final doubled = (p.isCaptain && captainPlayed) || (p.isVice && !captainPlayed);
      rows.add(
        PickPoints(
          pick: p,
          base: base,
          multiplier: doubled ? boosted : 1,
          events: evs,
          counted: p.status == 'starting' || chip == ChipType.benchBoost,
        ),
      );
    }
    return LineupPoints._(rows, chip);
  }
}
