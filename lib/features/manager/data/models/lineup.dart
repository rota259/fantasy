import 'package:equatable/equatable.dart';

/// حالة لاعب في تشكيلة ماتش (جدول lineups).
class Lineup extends Equatable {
  const Lineup({required this.playerId, required this.status});

  final String playerId;
  final String status; // starting | bench

  factory Lineup.fromMap(Map<String, dynamic> map) =>
      Lineup(playerId: map['player_id'].toString(), status: (map['status'] ?? 'bench') as String);

  @override
  List<Object?> get props => [playerId, status];
}

/// تشكيلة بعتها كابتن فريق للماتش (team_lineups) — المدير بيطبّقها.
class TeamLineup {
  const TeamLineup({required this.team, required this.starters, required this.bench, required this.applied});

  final String team;
  final int starters;
  final int bench;
  final bool applied;

  factory TeamLineup.fromMap(Map<String, dynamic> m) {
    final players = (m['players'] as List? ?? const []).cast<Map>();
    return TeamLineup(
      team: (m['team'] ?? '') as String,
      starters: players.where((p) => p['status'] == 'starting').length,
      bench: players.where((p) => p['status'] == 'bench').length,
      applied: m['applied'] == true,
    );
  }
}
