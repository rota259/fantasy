part of 'manager_players_cubit.dart';

enum ManagerPlayersStatus { loading, ready }

class ManagerPlayersState extends Equatable {
  const ManagerPlayersState({this.status = ManagerPlayersStatus.loading, this.players = const []});

  final ManagerPlayersStatus status;
  final List<Player> players;

  bool get isLoading => status == ManagerPlayersStatus.loading;

  @override
  List<Object?> get props => [status, players];
}
