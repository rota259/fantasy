part of 'match_cubit.dart';

abstract class MatchState extends Equatable {
  const MatchState();
  @override
  List<Object?> get props => [];
}

class MatchInitial extends MatchState {}

class MatchLoading extends MatchState {}

class MatchLoaded extends MatchState {
  final List<MatchModel> matches;
  const MatchLoaded(this.matches);

  @override
  List<Object?> get props => [matches];
}

class MatchError extends MatchState {
  final String error;
  const MatchError(this.error);

  @override
  List<Object?> get props => [error];
}
