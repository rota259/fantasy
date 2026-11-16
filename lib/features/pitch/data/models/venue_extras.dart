/// خبر من صاحب الملعب (venue_updates): تعديل أو تجديد.
class VenueUpdate {
  const VenueUpdate({required this.kind, required this.body, required this.createdAt});

  final String kind; // update · renovation
  final String body;
  final DateTime createdAt;

  bool get isRenovation => kind == 'renovation';

  factory VenueUpdate.fromMap(Map<String, dynamic> m) => VenueUpdate(
    kind: (m['kind'] ?? 'update') as String,
    body: (m['body'] ?? '') as String,
    createdAt: DateTime.parse(m['created_at'].toString()).toLocal(),
  );
}

/// لاعب في ترتيب هدافين الملعب (الأول = أسطورة الملعب).
class VenueStar {
  const VenueStar({
    required this.id,
    required this.name,
    required this.team,
    required this.goals,
    required this.assists,
    required this.matches,
    this.nickname,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? nickname;
  final String team;
  final String? imageUrl;
  final int goals;
  final int assists;
  final int matches;

  String get label => nickname == null ? name : '$name ($nickname)';

  factory VenueStar.fromMap(Map<String, dynamic> m) => VenueStar(
    id: m['id'].toString(),
    name: (m['name'] ?? '') as String,
    nickname: m['nickname'] as String?,
    team: (m['team'] ?? '') as String,
    imageUrl: m['image_url'] as String?,
    goals: (m['g'] as num?)?.toInt() ?? 0,
    assists: (m['a'] as num?)?.toInt() ?? 0,
    matches: (m['mp'] as num?)?.toInt() ?? 0,
  );
}

/// إحصائيات الملعب (venue_stats).
class VenueStats {
  const VenueStats({
    this.matches = 0,
    this.upcoming = 0,
    this.teams = 0,
    this.goals = 0,
    this.tournaments = 0,
    this.hours = const {},
    this.top = const [],
  });

  final int matches; // ماتشات خلصت
  final int upcoming;
  final int teams;
  final int goals;
  final int tournaments;
  final Map<int, int> hours; // الساعة (بتوقيت مصر) → عدد الماتشات آخر ٩٠ يوم
  final List<VenueStar> top;

  VenueStar? get legend => top.isEmpty ? null : top.first;

  factory VenueStats.fromMap(Map<String, dynamic> m) {
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    final h = (m['hours'] as Map?) ?? const {};
    return VenueStats(
      matches: n('matches'),
      upcoming: n('upcoming'),
      teams: n('teams'),
      goals: n('goals'),
      tournaments: n('tournaments'),
      hours: {for (final e in h.entries) int.parse(e.key.toString()): (e.value as num).toInt()},
      top: [for (final t in (m['top'] as List? ?? const [])) VenueStar.fromMap(Map<String, dynamic>.from(t as Map))],
    );
  }
}

/// ملعب صاحبه طالب توثيق (pending_venues) — للأدمن ومشرف المنطقة.
class PendingVenue {
  const PendingVenue({required this.id, required this.name, this.address, this.ownerName, this.ownerPhone});

  final String id;
  final String name;
  final String? address;
  final String? ownerName;
  final String? ownerPhone;

  factory PendingVenue.fromMap(Map<String, dynamic> m) => PendingVenue(
    id: m['id'].toString(),
    name: (m['name'] ?? '') as String,
    address: m['address'] as String?,
    ownerName: m['owner_name'] as String?,
    ownerPhone: m['owner_phone'] as String?,
  );
}

/// ماتش خلص في الملعب ومستني صاحبه يأكّد إنه اتلعب.
class VenueMatch {
  const VenueMatch({required this.id, required this.teams, required this.dateTime, this.scoreA, this.scoreB});

  final String id;
  final List<String> teams;
  final DateTime dateTime;
  final int? scoreA;
  final int? scoreB;

  factory VenueMatch.fromMap(Map<String, dynamic> m) => VenueMatch(
    id: m['id'].toString(),
    teams: List<String>.from(m['teams'] ?? const []),
    dateTime: DateTime.parse(m['date_time'].toString()).toLocal(),
    scoreA: (m['score_a'] as num?)?.toInt(),
    scoreB: (m['score_b'] as num?)?.toInt(),
  );
}
