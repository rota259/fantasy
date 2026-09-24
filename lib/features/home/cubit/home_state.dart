part of 'home_cubit.dart';

enum HomeStatus { loading, ready }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.points = 0,
    this.nextMatch,
    this.topPlayers = const [],
    this.todayPlayers = const [],
    this.weekFinal = false,
    this.weekLabel = '',
  });

  final HomeStatus status;
  final int points;
  final GameMatch? nextMatch;
  final List<WeekPlayer> topPlayers; // أعلى ٥ في الجولة (مباشر لحد الجمعة 4 الفجر)
  final List<WeekPlayer> todayPlayers; // أعلى ٥ النهارده
  final bool weekFinal; // الجولة قفلت (الجمعة من 4 الفجر لـ 12 بالليل)
  final String weekLabel;

  bool get isLoading => status == HomeStatus.loading;

  @override
  List<Object?> get props => [status, points, nextMatch, topPlayers, todayPlayers, weekFinal, weekLabel];
}
