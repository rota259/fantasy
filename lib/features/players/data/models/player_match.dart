/// ماتش لعبه اللاعب (player_matches): الفريقين والنتيجة وفريقه، وعمل إيه ونقطه.
class PlayerMatch {
  const PlayerMatch({
    required this.matchId,
    required this.teams,
    required this.dateTime,
    required this.team,
    required this.points,
    required this.items,
    this.scoreA,
    this.scoreB,
    this.finished = false,
    this.approved = false,
    this.starter = false,
    this.venue,
  });

  final String matchId;
  final List<String> teams;
  final DateTime dateTime;
  final int? scoreA;
  final int? scoreB;
  final bool finished;
  final bool approved; // النقط اتحسبت في الترتيب
  final String team; // فريقه
  final bool starter; // أساسي (ولا احتياطي)
  final String? venue;
  final int points;
  final List<({String label, int count, int points})> items; // جول ×٢ = +١٠ …

  String get teamA => teams.isNotEmpty ? teams.first : '';
  String get teamB => teams.length > 1 ? teams[1] : '';

  /// "٣ - ١" أو "لايف" لو لسه مخلصش.
  String get score => (scoreA == null || scoreB == null) ? '-' : '$scoreA - $scoreB';

  /// كسب · تعادل · خسارة (من ناحية فريقه) — null لو الماتش مخلصش.
  String? get result {
    if (!finished || scoreA == null || scoreB == null) return null;
    final mine = team == teamA ? scoreA! : scoreB!, theirs = team == teamA ? scoreB! : scoreA!;
    return mine > theirs ? 'كسب' : (mine == theirs ? 'تعادل' : 'خسارة');
  }

  factory PlayerMatch.fromMap(Map<String, dynamic> m) => PlayerMatch(
    matchId: m['match_id'].toString(),
    teams: List<String>.from(m['teams'] ?? const []),
    dateTime: DateTime.parse(m['date_time'].toString()).toLocal(),
    scoreA: (m['score_a'] as num?)?.toInt(),
    scoreB: (m['score_b'] as num?)?.toInt(),
    finished: m['status'] == 'finished',
    approved: m['review_status'] == 'approved',
    team: (m['team'] ?? '') as String,
    starter: m['lineup'] == 'starting',
    venue: m['venue_name'] as String?,
    points: (m['points'] as num?)?.toInt() ?? 0,
    items: [
      for (final i in (m['items'] as List? ?? const []).cast<Map>())
        (
          label: (i['k'] ?? '') as String,
          count: (i['n'] as num?)?.toInt() ?? 0,
          points: (i['p'] as num?)?.toInt() ?? 0,
        ),
    ],
  );
}
