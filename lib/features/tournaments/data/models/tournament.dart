import 'package:equatable/equatable.dart';

/// بطولة (tournaments): دوري · مجموعات + خروج مغلوب · خروج مغلوب.
class Tournament extends Equatable {
  const Tournament({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.format,
    required this.teamCount,
    required this.startsAt,
    required this.status,
    this.groupsCount = 0,
    this.prize,
    this.sponsor,
    this.champion,
    this.createdBy,
  });

  final String id;
  final String name;
  final int zoneId;
  final String format; // league · groups · knockout
  final int teamCount;
  final int groupsCount;
  final DateTime startsAt;
  final String status; // registration · running · finished
  final String? prize;
  final String? sponsor;
  final String? champion;
  final String? createdBy;

  bool get isRegistration => status == 'registration';
  bool get isRunning => status == 'running';
  bool get isFinished => status == 'finished';
  bool get hasBracket => format != 'league';

  String get formatLabel => switch (format) {
    'league' => 'دوري (كله ضد كله)',
    'groups' => 'مجموعات + خروج المغلوب',
    _ => 'خروج المغلوب',
  };

  String get statusLabel => switch (status) {
    'registration' => 'التسجيل مفتوح',
    'running' => 'شغّالة ⚽',
    _ => 'خلصت 🏆',
  };

  factory Tournament.fromMap(Map<String, dynamic> m) => Tournament(
    id: m['id'].toString(),
    name: (m['name'] ?? '') as String,
    zoneId: (m['zone_id'] as num).toInt(),
    format: (m['format'] ?? 'league') as String,
    teamCount: (m['team_count'] as num?)?.toInt() ?? 0,
    groupsCount: (m['groups_count'] as num?)?.toInt() ?? 0,
    startsAt: DateTime.parse(m['starts_at'] as String).toLocal(),
    status: (m['status'] ?? 'registration') as String,
    prize: m['prize'] as String?,
    sponsor: m['sponsor'] as String?,
    champion: m['champion'] as String?,
    createdBy: m['created_by']?.toString(),
  );

  @override
  List<Object?> get props => [id, name, status, champion, teamCount, groupsCount, startsAt, prize, sponsor];
}

/// فريق في بطولة (أو طلب مشاركة).
class TournamentTeam {
  const TournamentTeam({required this.team, required this.status, this.group, this.phone, this.note});
  final String team;
  final String status; // pending · approved · rejected
  final String? group;
  final String? phone;
  final String? note;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  factory TournamentTeam.fromMap(Map<String, dynamic> m) => TournamentTeam(
    team: (m['team'] ?? '') as String,
    status: (m['status'] ?? 'approved') as String,
    group: m['group_label'] as String?,
    phone: m['phone'] as String?,
    note: m['note'] as String?,
  );
}

/// صف في ترتيب البطولة.
class TournamentRow {
  const TournamentRow({
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.gd,
    required this.pts,
    this.group,
  });
  final String? group;
  final String team;
  final int played, won, drawn, lost, gd, pts;

  factory TournamentRow.fromMap(Map<String, dynamic> m) => TournamentRow(
    group: m['group_label'] as String?,
    team: (m['team'] ?? '') as String,
    played: (m['played'] as num).toInt(),
    won: (m['won'] as num).toInt(),
    drawn: (m['drawn'] as num).toInt(),
    lost: (m['lost'] as num).toInt(),
    gd: (m['gd'] as num).toInt(),
    pts: (m['pts'] as num).toInt(),
  );
}

/// مكان في شجرة خروج المغلوب.
class BracketSlot {
  const BracketSlot({required this.round, required this.slot, this.team, this.matchId});
  final int round;
  final int slot;
  final String? team;
  final String? matchId;

  factory BracketSlot.fromMap(Map<String, dynamic> m) => BracketSlot(
    round: (m['round'] as num).toInt(),
    slot: (m['slot'] as num).toInt(),
    team: m['team'] as String?,
    matchId: m['match_id']?.toString(),
  );
}

/// جايزة: الهداف · أحسن حارس · أحسن لاعب.
class TournamentAward {
  const TournamentAward({
    required this.award,
    required this.name,
    required this.team,
    required this.value,
    this.playerId,
  });
  final String award; // scorer · keeper · mvp
  final String? playerId;
  final String name;
  final String team;
  final int value;

  String get title => switch (award) {
    'scorer' => '⚽ الهداف',
    'keeper' => '🧤 أحسن حارس',
    _ => '⭐ أحسن لاعب',
  };

  String get unit => award == 'scorer' ? 'جول' : 'نقطة';

  factory TournamentAward.fromMap(Map<String, dynamic> m) => TournamentAward(
    award: (m['award'] ?? '') as String,
    playerId: m['player_id']?.toString(),
    name: (m['name'] ?? '') as String,
    team: (m['team'] ?? '') as String,
    value: (m['value'] as num?)?.toInt() ?? 0,
  );
}
