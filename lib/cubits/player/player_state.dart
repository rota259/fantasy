part of 'player_cubit.dart';

abstract class PlayerState extends Equatable {
  const PlayerState();
  @override
  List<Object?> get props => [];
}

class PlayerInitial extends PlayerState {}

class PlayerLoading extends PlayerState {}

class PlayerLoaded extends PlayerState {
  final List<PlayerModel> players;
  const PlayerLoaded(this.players);

  @override
  List<Object?> get props => [players];
}

class PlayerError extends PlayerState {
  final String error;
  const PlayerError(this.error);

  @override
  List<Object?> get props => [error];
}
