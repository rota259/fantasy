part of 'manager_match_cubit.dart';

enum ManagerMatchStatus { loading, ready }

class ManagerMatchState extends Equatable {
  const ManagerMatchState({
    this.status = ManagerMatchStatus.loading,
    this.players = const [],
    this.events = const [],
    this.lineup = const {},
  });

  final ManagerMatchStatus status;
  final List<Player> players;
  final List<MatchEvent> events;
  final Map<String, String> lineup; // playerId → starting|bench

  bool get isLoading => status == ManagerMatchStatus.loading;

  ManagerMatchState copyWith({List<Player>? players, List<MatchEvent>? events, Map<String, String>? lineup}) =>
      ManagerMatchState(
        status: status,
        players: players ?? this.players,
        events: events ?? this.events,
        lineup: lineup ?? this.lineup,
      );

  @override
  List<Object?> get props => [status, players, events, lineup];
}
