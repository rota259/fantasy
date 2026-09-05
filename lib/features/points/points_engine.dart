import '../events/data/models/match_event.dart';
import '../players/data/models/player.dart';

/// محرك احتساب النقاط — قواعد الخماسي (متكيّفة من FPL).
/// النقاط بتتحسب من نوع الحدث + مركز اللاعب (مفيش أي رقم ثابت في الشاشات).
abstract final class PointsEngine {
  PointsEngine._();

  /// نقاط حدث واحد حسب النوع والمركز.
  static int eventPoints(String type, String position) {
    final isDefensive = position == 'GK' || position == 'DEF';
    final isMid = position == 'MID';
    return switch (type) {
      'appearance' => 1,
      'goal' => isDefensive ? 6 : (isMid ? 5 : 4),
      'assist' => 3,
      'cleanSheet' => isDefensive ? 4 : (isMid ? 1 : 0),
      'save' => 1,
      'penaltySave' => 5,
      'motm' => 3,
      'yellowCard' => -1,
      'redCard' => -3,
      'ownGoal' => -2,
      'penaltyMiss' => -2,
      _ => 0,
    };
  }

  /// وصف الحدث بالعربي للبث الحي.
  static String eventLabel(String type) => switch (type) {
        'goal' => 'جوووول',
        'assist' => 'تمريرة حاسمة',
        'cleanSheet' => 'شباك نظيفة',
        'save' => 'تصدّي مهم',
        'penaltySave' => 'صدّ بلنتي',
        'motm' => 'نجم الماتش',
        'yellowCard' => 'كارت أصفر',
        'redCard' => 'كارت أحمر',
        'ownGoal' => 'جول عكسي',
        'penaltyMiss' => 'أضاع بلنتي',
        'appearance' => 'شارك',
        _ => type,
      };

  /// إجمالي نقاط لاعب من أحداثه.
  static int playerPoints(String position, Iterable<MatchEvent> events) {
    return events.fold(0, (sum, e) => sum + eventPoints(e.type, position));
  }

  /// مساهمة الكابتن (نقاطه × 2) — للتفصيل في التحدّي.
  static int captainContribution(Player? captain, Iterable<MatchEvent> events) {
    if (captain == null) return 0;
    final own = events.where((e) => e.playerId == captain.id);
    return playerPoints(captain.position, own) * 2;
  }

  /// نقاط تشكيلة المستخدم في الجولة (نقاط الكابتن × 2).
  static int squadPoints(
    List<Player> squad,
    String? captainId,
    Iterable<MatchEvent> events,
  ) {
    final byId = {for (final p in squad) p.id: p};
    var total = 0;
    for (final e in events) {
      final p = byId[e.playerId];
      if (p == null) continue;
      final pts = eventPoints(e.type, p.position);
      total += e.playerId == captainId ? pts * 2 : pts;
    }
    return total;
  }
}
