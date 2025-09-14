
part of 'team_cubit.dart';

abstract class TeamState extends Equatable {
  const TeamState();
  @override
  List<Object?> get props => [];
}

class TeamInitial extends TeamState {}

class TeamLoading extends TeamState {}

class TeamLoaded extends TeamState {
  final List<PlayerModel> team;
  const TeamLoaded(this.team);

  @override
  List<Object?> get props => [team];
}

class TeamError extends TeamState {
  final String error;
  const TeamError(this.error);

  @override
  List<Object?> get props => [error];
}
