part of 'league_cubit.dart';

abstract class LeagueState extends Equatable {
  const LeagueState();
  @override
  List<Object?> get props => [];
}

class LeagueInitial extends LeagueState {}

class LeagueLoading extends LeagueState {}

class LeagueLoaded extends LeagueState {
  final List<UserModel> members;
  const LeagueLoaded(this.members);

  @override
  List<Object?> get props => [members];
}

class LeagueError extends LeagueState {
  final String error;
  const LeagueError(this.error);

  @override
  List<Object?> get props => [error];
}
