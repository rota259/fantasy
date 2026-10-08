import '../events/data/models/match_event.dart';
import 'data/models/game_match.dart';

/// حدث (أو كذا مرة من نفس الحدث) للاعب في الملخص.
typedef EventGroup = ({String type, String playerId, String? otherPlayerId, List<int?> minutes});

/// حسابات الماتش لايف من الأحداث (نفس السيرفر):
///   • مين في الملعب دلوقتي: الأساسيين + اللي نزلوا تبديل − اللي طلعوا تبديل − اللي خدوا أحمر.
///   • النتيجة: أهداف كل فريق + الجول العكسي من لاعيبة الفريق التاني.
abstract final class MatchLive {
  MatchLive._();

  /// [lineup]: playerId → starting | bench.
  static Set<String> onPitch(Map<String, String> lineup, List<MatchEvent> events) {
    final on = {
      for (final e in lineup.entries)
        if (e.value == 'starting') e.key,
    };
    for (final e in _ordered(events)) {
      if (e.type == 'sub') {
        on.add(e.playerId);
        if (e.otherPlayerId != null) on.remove(e.otherPlayerId);
      } else if (e.type == 'redCard') {
        on.remove(e.playerId);
      }
    }
    return on;
  }

  /// الاحتياطي اللي لسه منزلش.
  static Set<String> benchLeft(Map<String, String> lineup, List<MatchEvent> events) {
    final used = {
      for (final e in events)
        if (e.type == 'sub') e.playerId,
    };
    return {
      for (final e in lineup.entries)
        if (e.value == 'bench' && !used.contains(e.key)) e.key,
    };
  }

  /// النتيجة — [teamOf]: playerId → فريقه.
  static ({int a, int b}) score(List<String> teams, List<MatchEvent> events, Map<String, String> teamOf) {
    var a = 0, b = 0;
    if (teams.length < 2) return (a: 0, b: 0);
    for (final e in events) {
      final t = teamOf[e.playerId];
      if (e.type == 'goal') {
        if (t == teams[0]) a++;
        if (t == teams[1]) b++;
      } else if (e.type == 'ownGoal') {
        if (t == teams[0]) b++;
        if (t == teams[1]) a++;
      }
    }
    return (a: a, b: b);
  }

  /// بالدقيقة (اللي من غير دقيقة في الآخر بترتيب التسجيل).
  static List<MatchEvent> _ordered(List<MatchEvent> events) {
    final list = [...events];
    final idx = {for (final (i, e) in events.indexed) e.id: i};
    list.sort((x, y) {
      final c = (x.minute ?? 1 << 20).compareTo(y.minute ?? 1 << 20);
      return c != 0 ? c : idx[x.id]!.compareTo(idx[y.id]!);
    });
    return list;
  }

  /// الفرق اللي بتلعب دلوقتي (الماتش بدأ ولسه مخلصش).
  static Set<String> liveTeams(List<GameMatch> matches, [DateTime? now]) {
    final n = now ?? DateTime.now();
    return {
      for (final m in matches)
        if (!m.isFinished && !m.dateTime.isAfter(n)) ...m.teams,
    };
  }

  /// الملخص: نفس اللاعب + نفس الحدث = سطر واحد بعدد المرات ودقايقها (هاتريك = الاسم مرة و٣ كور).
  /// الأحداث المختلفة كل واحد في سطر. الترتيب بأول مرة حصل فيها.
  static List<EventGroup> grouped(List<MatchEvent> events) {
    final out = <String, EventGroup>{};
    for (final e in _ordered(events)) {
      final key = '${e.type}|${e.playerId}|${e.otherPlayerId ?? ''}';
      final g = out[key];
      out[key] = g == null
          ? (type: e.type, playerId: e.playerId, otherPlayerId: e.otherPlayerId, minutes: [e.minute])
          : (type: g.type, playerId: g.playerId, otherPlayerId: g.otherPlayerId, minutes: [...g.minutes, e.minute]);
    }
    return out.values.toList();
  }

  /// الأحداث بالترتيب (للتايملاين).
  static List<MatchEvent> timeline(List<MatchEvent> events) => _ordered(events);
}
