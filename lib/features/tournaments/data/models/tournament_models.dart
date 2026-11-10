part of 'tournament.dart';

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
    'scorer' => 'الهداف',
    'keeper' => '🧤 أحسن حارس',
    _ => 'أحسن لاعب',
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

/// فانتازي بطولة واحدة: تشكيلتي فيها ونقطي وترتيبي + ترتيب الناس.
class TournamentFantasy {
  const TournamentFantasy({
    this.canPlay = false,
    this.finished = false,
    this.live = false,
    this.players = const [],
    this.mine = const [],
    this.captain,
    this.myPoints = 0,
    this.myRank,
    this.standings = const [],
  });

  final bool canPlay; // من منطقة البطولة ومش حساب مدير
  final bool finished;
  final bool live; // فيه ماتش شغال → التشكيلة مقفولة
  final List<FantasyPlayer> players;
  final List<String> mine; // ids
  final String? captain;
  final int myPoints;
  final int? myRank;
  final List<({int rank, String name, int points, bool mine})> standings;

  bool get open => canPlay && !finished && !live;

  factory TournamentFantasy.fromMap(Map<String, dynamic> m) {
    final mine = ((m['mine'] as List?) ?? const []).cast<Map<String, dynamic>>();
    String? cap;
    for (final x in mine) {
      if (x['captain'] == true) cap = x['id'].toString();
    }
    return TournamentFantasy(
      canPlay: m['can_play'] == true,
      finished: m['finished'] == true,
      live: m['live'] == true,
      players: [
        for (final p in ((m['players'] as List?) ?? const []).cast<Map<String, dynamic>>())
          (
            id: p['id'].toString(),
            name: p['name'] as String,
            team: p['team'] as String,
            gk: p['gk'] == true,
            imageUrl: p['image_url'] as String?,
            points: (p['points'] as num?)?.toInt() ?? 0,
          ),
      ],
      mine: [for (final x in mine) x['id'].toString()],
      captain: cap,
      myPoints: (m['my_points'] as num?)?.toInt() ?? 0,
      myRank: (m['my_rank'] as num?)?.toInt(),
      standings: [
        for (final r in ((m['standings'] as List?) ?? const []).cast<Map<String, dynamic>>())
          (
            rank: (r['rank'] as num).toInt(),
            name: (r['name'] ?? '') as String,
            points: (r['points'] as num?)?.toInt() ?? 0,
            mine: r['mine'] == true,
          ),
      ],
    );
  }
}
