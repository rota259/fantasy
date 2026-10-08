part of 'manager_match_cubit.dart';

enum ManagerMatchStatus { loading, ready }

class ManagerMatchState extends Equatable {
  const ManagerMatchState({
    this.status = ManagerMatchStatus.loading,
    this.players = const [],
    this.events = const [],
    this.lineup = const {},
    this.format = 5,
  });

  final ManagerMatchStatus status;
  final List<Player> players;
  final List<MatchEvent> events;
  final Map<String, String> lineup; // playerId → starting|bench
  final int format; // خماسي (٥) أو سداسي (٦): عدد الأساسيين بالحارس

  /// آخر عدد للفريق في الماتش (الأساسي + الاحتياطي).
  static const squadMax = 7;

  bool get isLoading => status == ManagerMatchStatus.loading;

  ManagerMatchState copyWith({
    List<Player>? players,
    List<MatchEvent>? events,
    Map<String, String>? lineup,
    int? format,
  }) => ManagerMatchState(
    status: status,
    players: players ?? this.players,
    events: events ?? this.events,
    lineup: lineup ?? this.lineup,
    format: format ?? this.format,
  );

  @override
  List<Object?> get props => [status, players, events, lineup, format];
}
