part of 'team_of_week_cubit.dart';

enum TeamOfWeekStatus { loading, ready }

class TeamOfWeekState extends Equatable {
  const TeamOfWeekState({
    required this.window,
    this.status = TeamOfWeekStatus.loading,
    this.players = const [],
  });

  final WeekWindow window;
  final TeamOfWeekStatus status;
  final List<WeekPlayer> players; // نقاط الجولة (الأعلى أولًا)

  bool get isLoading => status == TeamOfWeekStatus.loading;
  bool get isCurrent => window == WeekWindow.current();

  /// أعلى لاعيبة في مركز معيّن (بحد أقصى).
  List<WeekPlayer> byPosition(String pos, {int max = 5}) =>
      players.where((p) => p.position == pos).take(max).toList();

  /// تشكيلة الخماسي: [حارس، دفاع، وسط، هجوم، أحسن واحد فاضل من الملعب].
  List<WeekPlayer?> get lineup {
    WeekPlayer? best(bool Function(WeekPlayer) test, Set<String> used) {
      for (final p in players) {
        if (!used.contains(p.id) && test(p)) return p;
      }
      return null;
    }

    final used = <String>{};
    final out = <WeekPlayer?>[];
    for (final pos in const ['GK', 'DEF', 'MID', 'FWD']) {
      final p = best((x) => x.position == pos, used);
      if (p != null) used.add(p.id);
      out.add(p);
    }
    out.add(best((x) => x.position != 'GK', used));
    return out;
  }

  TeamOfWeekState copyWith({WeekWindow? window, TeamOfWeekStatus? status, List<WeekPlayer>? players}) =>
      TeamOfWeekState(
        window: window ?? this.window,
        status: status ?? this.status,
        players: players ?? this.players,
      );

  @override
  List<Object?> get props => [window, status, players];
}
