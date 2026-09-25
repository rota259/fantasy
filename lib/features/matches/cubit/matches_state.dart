part of 'matches_cubit.dart';

enum MatchesStatus { initial, loading, loaded }

class MatchesState extends Equatable {
  const MatchesState({
    this.status = MatchesStatus.initial,
    this.matches = const [],
    this.results = const [],
    this.follows = const {},
  });

  final MatchesStatus status;
  final List<GameMatch> matches; // القادمة
  final List<GameMatch> results; // اللي خلصت (الأحدث الأول)
  final Set<String> follows; // ids الماتشات اللي بتابعها لايف

  bool get isLoading => status == MatchesStatus.loading;
  bool get hasData => matches.isNotEmpty;

  MatchesState copyWith({Set<String>? follows}) =>
      MatchesState(status: status, matches: matches, results: results, follows: follows ?? this.follows);

  @override
  List<Object?> get props => [status, matches, results, follows];
}
