part of 'players_cubit.dart';

enum PlayersStatus { initial, loading, loaded, error }

class PlayersState extends Equatable {
  const PlayersState({
    this.status = PlayersStatus.initial,
    this.players = const [],
    this.message,
  });

  final PlayersStatus status;
  final List<Player> players;
  final String? message;

  bool get isLoading => status == PlayersStatus.loading;

  @override
  List<Object?> get props => [status, players, message];
}
