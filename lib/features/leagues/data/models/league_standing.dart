import 'package:equatable/equatable.dart';

import 'league.dart';

/// صف في ترتيب الدوري.
class LeagueStanding extends Equatable {
  /// الترتيب بيتحمّل صفحات (مش كل الدوري مرة واحدة).
  static const pageSize = 50;

  const LeagueStanding({
    required this.rank,
    required this.userId,
    required this.name,
    required this.points,
    this.photoUrl,
    this.lowPicks = 0,
    this.moved,
  });

  factory LeagueStanding.fromMap(Map<String, dynamic> m) => LeagueStanding(
    rank: (m['rank'] as num).toInt(),
    userId: m['user_id'].toString(),
    name: (m['name'] ?? '') as String,
    points: (m['points'] as num?)?.toInt() ?? 0,
    photoUrl: m['photo_url'] as String?,
    lowPicks: (m['low_picks'] as num?)?.toInt() ?? 0,
    moved: (m['moved'] as num?)?.toInt(),
  );

  final int rank;
  final String userId;
  final String name;
  final int points;
  final String? photoUrl;
  final int lowPicks; // لاعيبة امتلاكها أقل من ٢٥٪ (كسر التعادل)
  final int? moved; // اتحرّك كام مركز من أول الجولة (+ طلع · − نزل) — الدوري العام بس

  String get initials => name.trim().length >= 2 ? name.trim().substring(0, 2) : (name.isEmpty ? '؟' : name);

  @override
  List<Object?> get props => [rank, userId, name, points, photoUrl, lowPicks, moved];
}

/// دوري المستخدم مع ترتيبه فيه (لصفوف قائمة الدوريات).
class MyLeague extends Equatable {
  const MyLeague({required this.league, required this.userRank});

  final League league;
  final int userRank;

  @override
  List<Object?> get props => [league, userRank];
}
