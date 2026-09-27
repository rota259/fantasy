part of 'team_of_week_cubit.dart';

enum TeamOfWeekStatus { loading, ready }

class TeamOfWeekState extends Equatable {
  const TeamOfWeekState({
    required this.window,
    this.status = TeamOfWeekStatus.loading,
    this.published,
    this.ranking = const [],
    this.tie,
    this.tied = const [],
    this.slots = 0,
  });

  final WeekWindow window;
  final TeamOfWeekStatus status;
  final List<WeekPlayer>? published; // الخمسة المعتمدين (null = لسه)
  final List<WeekPlayer> ranking; // ترتيب الجولة (بيظهر بعد الاعتماد بس)
  final PollView? tie; // تصويت التعادل على آخر مكان (لو فيه)
  final List<WeekPlayer> tied; // المتعادلين (للتصويت)
  final int slots; // كام مكان عليه تعادل

  bool get isLoading => status == TeamOfWeekStatus.loading;
  bool get isCurrent => window == WeekWindow.current();
  bool get isPublished => published != null;

  /// الخمسة مترتّبين على الخماسي.
  List<WeekPlayer?> get spots => TeamOfWeek.arrange(published ?? const []);

  TeamOfWeekState copyWith({TeamOfWeekStatus? status}) => TeamOfWeekState(
    window: window,
    status: status ?? this.status,
    published: published,
    ranking: ranking,
    tie: tie,
    tied: tied,
    slots: slots,
  );

  @override
  List<Object?> get props => [window, status, published, ranking, tie, tied, slots];
}
