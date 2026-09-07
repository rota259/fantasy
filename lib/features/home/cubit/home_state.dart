part of 'home_cubit.dart';

enum HomeStatus { loading, ready }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.points = 0,
    this.nextMatch,
    this.topPlayers = const [],
  });

  final HomeStatus status;
  final int points;
  final GameMatch? nextMatch;
  final List<WeekPlayer> topPlayers;

  bool get isLoading => status == HomeStatus.loading;

  @override
  List<Object?> get props => [status, points, nextMatch, topPlayers];
}
