part of 'matches_cubit.dart';

enum MatchesStatus { initial, loading, loaded }

class MatchesState extends Equatable {
  const MatchesState({
    this.status = MatchesStatus.initial,
    this.matches = const [],
    this.results = const [],
  });

  final MatchesStatus status;
  final List<GameMatch> matches; // القادمة
  final List<GameMatch> results; // اللي خلصت (الأحدث الأول)

  bool get isLoading => status == MatchesStatus.loading;
  bool get hasData => matches.isNotEmpty;

  @override
  List<Object?> get props => [status, matches, results];
}
