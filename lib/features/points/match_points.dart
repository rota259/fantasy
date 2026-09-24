import '../events/data/models/match_event.dart';
import '../pick/data/models/pick.dart';
import '../players/data/models/player.dart';
import 'points_engine.dart';

/// نقاط لاعب واحد في تشكيلة اليوزر في ماتش.
class PickPoints {
  const PickPoints({
    required this.pick,
    required this.base,
    required this.multiplier,
    required this.events,
  });

  final Pick pick;
  final int base; // نقاطه من الأحداث
  final int multiplier; // 2 = الكابتن (أو النائب لو الكابتن ملعبش)
  final List<MatchEvent> events;

  bool get counted => pick.status == 'starting'; // الاحتياطي مش بيتحسب
  int get total => counted ? base * multiplier : 0;
}

/// نقاط تشكيلة يوزر في ماتش — **نفس** قاعدة الداتابيز (fn_user_points):
///   • الأساسيين بس بيتحسبوا.
///   • الكابتن ×2 لو ليه أي حدث في الماتش (لعب).
///   • لو الكابتن ملعبش → الكابتن الاحتياطي ×2.
class MatchPoints {
  MatchPoints._(this.rows);

  final List<PickPoints> rows;

  int get total => rows.fold(0, (s, r) => s + r.total);
  PickPoints? of(String playerId) {
    for (final r in rows) {
      if (r.pick.playerId == playerId) return r;
    }
    return null;
  }

  factory MatchPoints.compute({
    required List<Pick> picks,
    required List<MatchEvent> events, // أحداث الماتش ده بس
    required Map<String, Player> players,
  }) {
    List<MatchEvent> eventsOf(String id) => events.where((e) => e.playerId == id).toList();
    final captainPlayed = picks.any((p) => p.isCaptain && eventsOf(p.playerId).isNotEmpty);

    final rows = <PickPoints>[];
    for (final p in picks) {
      final evs = eventsOf(p.playerId);
      final pos = players[p.playerId]?.position ?? '';
      final base = evs.fold(0, (s, e) => s + PointsEngine.eventPoints(e.type, pos));
      final doubled = (p.isCaptain && captainPlayed) || (p.isVice && !captainPlayed);
      rows.add(PickPoints(pick: p, base: base, multiplier: doubled ? 2 : 1, events: evs));
    }
    return MatchPoints._(rows);
  }
}
