part of 'team_of_week_cubit.dart';

enum TeamOfWeekStatus { loading, ready }

class TeamOfWeekState extends Equatable {
  const TeamOfWeekState({
    this.status = TeamOfWeekStatus.loading,
    this.week = 1,
    this.players = const [],
  });

  final TeamOfWeekStatus status;
  final int week;
  final List<WeekPlayer> players;

  bool get isLoading => status == TeamOfWeekStatus.loading;

  /// أعلى لاعيبة في مركز معيّن (بحد أقصى).
  List<WeekPlayer> byPosition(String pos, {int max = 5}) =>
      players.where((p) => p.position == pos).take(max).toList();

  @override
  List<Object?> get props => [status, week, players];
}
