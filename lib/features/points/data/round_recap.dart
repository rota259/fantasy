/// ملخص جولتي (my_round_recap): للـ "جولتك في ٥ سلايدز".
class RoundRecap {
  const RoundRecap({
    required this.points,
    required this.rankNow,
    required this.users,
    this.prevRank,
    this.bestName,
    this.bestPoints = 0,
    this.captainName,
    this.captainPoints = 0,
    this.scorers = 0,
    this.chip,
  });

  final int points;
  final int rankNow;
  final int? prevRank; // ترتيبي في أول الجولة (null = لسه مفيش صورة)
  final int users;
  final String? bestName;
  final int bestPoints;
  final String? captainName;
  final int captainPoints; // نقطه من غير المضاعفة
  final int scorers; // كام أساسي جاب نقط
  final String? chip;

  /// طلعت كام مركز (+) أو نزلت (−).
  int get moved => prevRank == null ? 0 : prevRank! - rankNow;

  factory RoundRecap.fromMap(Map<String, dynamic> m) => RoundRecap(
    points: (m['points'] as num?)?.toInt() ?? 0,
    rankNow: (m['rank_now'] as num?)?.toInt() ?? 0,
    prevRank: (m['prev_rank'] as num?)?.toInt(),
    users: (m['users'] as num?)?.toInt() ?? 0,
    bestName: m['best_name'] as String?,
    bestPoints: (m['best_points'] as num?)?.toInt() ?? 0,
    captainName: m['captain_name'] as String?,
    captainPoints: (m['captain_points'] as num?)?.toInt() ?? 0,
    scorers: (m['scorers'] as num?)?.toInt() ?? 0,
    chip: m['chip'] as String?,
  );
}
