part of 'match_pick_cubit.dart';

enum MatchPickStatus { loading, ready }

class MatchPickState extends Equatable {
  const MatchPickState({
    this.status = MatchPickStatus.loading,
    this.players = const [],
    this.sel = const {},
    this.captainId,
  });

  final MatchPickStatus status;
  final List<Player> players;
  final Map<String, String> sel; // playerId → starting | bench
  final String? captainId;

  bool get isLoading => status == MatchPickStatus.loading;
  int get startingCount => sel.values.where((v) => v == 'starting').length;
  int get benchCount => sel.values.where((v) => v == 'bench').length;

  MatchPickState copyWith({
    Map<String, String>? sel,
    String? captainId,
    bool clearCaptain = false,
  }) {
    return MatchPickState(
      status: status,
      players: players,
      sel: sel ?? this.sel,
      captainId: clearCaptain ? null : (captainId ?? this.captainId),
    );
  }

  @override
  List<Object?> get props => [status, players, sel, captainId];
}
