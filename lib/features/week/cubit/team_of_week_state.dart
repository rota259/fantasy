part of 'team_of_week_cubit.dart';

enum TeamOfWeekStatus { loading, ready }

class TeamOfWeekState extends Equatable {
  const TeamOfWeekState({
    required this.window,
    this.status = TeamOfWeekStatus.loading,
    this.players = const [],
    this.tie,
  });

  final WeekWindow window;
  final TeamOfWeekStatus status;
  final List<WeekPlayer> players; // نقاط الجولة (الأعلى أولًا)
  final PollView? tie; // تصويت التعادل على آخر مكان (لو اتعمل)

  bool get isLoading => status == TeamOfWeekStatus.loading;
  bool get isCurrent => window == WeekWindow.current();

  TeamOfWeek get team => TeamOfWeek.build(players);

  /// التعادل بيتحسم بتصويت بس لما الجولة تبقى نهائي (قبلها الترتيب بيتغيّر كل شوية).
  bool get contested => team.hasTie && window.isFinal();

  /// الخمسة مترتّبين على الخماسي. وقت التصويت المكان المتنازع عليه بيفضل فاضي لحد ما يتحسم.
  List<WeekPlayer?> get spots {
    final t = tie;
    final List<String> winners;
    if (!contested) {
      winners = team.tied.map((p) => p.id).toList(); // مباشر: أول المتعادلين
    } else if (t != null && !t.poll.open) {
      winners = t.winners.map((o) => o.playerId ?? '').toList();
    } else {
      winners = const [];
    }
    return TeamOfWeek.arrange(team.lineup(winnerIds: winners));
  }

  TeamOfWeekState copyWith({TeamOfWeekStatus? status}) =>
      TeamOfWeekState(window: window, status: status ?? this.status, players: players, tie: tie);

  @override
  List<Object?> get props => [window, status, players, tie];
}
