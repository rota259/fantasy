import 'player_round_points.dart';

/// ماتش لعبه لاعب في جولة: ضد مين · النتيجة · نقطه · عمل إيه (player_round_matches).
class PlayerMatchLine {
  const PlayerMatchLine({
    required this.matchId,
    required this.teams,
    required this.dateTime,
    required this.finished,
    required this.points,
    this.scoreA,
    this.scoreB,
    this.items = const [],
  });

  final String matchId;
  final List<String> teams;
  final DateTime dateTime;
  final bool finished;
  final int points;
  final int? scoreA;
  final int? scoreB;
  final List<ScoreItem> items;

  /// الفريق التاني بالنسبة لفريق اللاعب.
  String opponentOf(String team) => teams.length < 2 ? '' : (teams[0] == team ? teams[1] : teams[0]);

  String get score => '${scoreA ?? 0} - ${scoreB ?? 0}';

  factory PlayerMatchLine.fromMap(Map<String, dynamic> m) => PlayerMatchLine(
    matchId: m['match_id'].toString(),
    teams: ((m['teams'] as List?) ?? const []).map((e) => e.toString()).toList(),
    dateTime: DateTime.parse(m['date_time'] as String).toLocal(),
    finished: m['status'] == 'finished',
    points: (m['points'] as num?)?.toInt() ?? 0,
    scoreA: (m['score_a'] as num?)?.toInt(),
    scoreB: (m['score_b'] as num?)?.toInt(),
    items: PlayerRoundPoints.itemsFrom(m['items']),
  );
}
