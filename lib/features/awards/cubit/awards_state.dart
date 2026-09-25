part of 'awards_cubit.dart';

class AwardsState extends Equatable {
  const AwardsState({this.loading = true, this.polls = const {}, this.busy = false});

  final bool loading;
  final Map<String, PollView> polls; // kind → آخر تصويت من النوع ده
  final bool busy; // صوت بيتبعت دلوقتي

  /// التابات المتاحة: الجولة دايمًا، والموسم لو اتعمل.
  List<(String, String)> get tabs => [
    (PollKind.goalWeek, 'هدف الجولة'),
    (PollKind.saveWeek, 'تصدّي الجولة'),
    if (polls.containsKey(PollKind.goalSeason)) (PollKind.goalSeason, 'هدف الموسم 🏆'),
    if (polls.containsKey(PollKind.saveSeason)) (PollKind.saveSeason, 'تصدّي الموسم 🏆'),
  ];

  AwardsState copyWith({Map<String, PollView>? polls, bool? busy}) =>
      AwardsState(loading: loading, polls: polls ?? this.polls, busy: busy ?? this.busy);

  @override
  List<Object?> get props => [loading, polls, busy];
}
