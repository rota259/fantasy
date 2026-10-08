part of 'match_center_cubit.dart';

class MatchCenterState extends Equatable {
  const MatchCenterState({
    required this.match,
    this.loading = true,
    this.events = const [],
    this.lineup = const {},
    this.players = const {},
  });

  final GameMatch match;
  final bool loading;
  final List<MatchEvent> events;
  final Map<String, String> lineup; // playerId → starting | bench
  final Map<String, Player> players;

  String name(String? id) => players[id]?.name ?? '—';
  String? teamOf(String id) => players[id]?.team;

  @override
  List<Object?> get props => [match, loading, events, lineup, players];
}
