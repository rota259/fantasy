part of 'live_round_cubit.dart';

enum LiveRoundStatus { loading, ready, error }

class LiveRoundState extends Equatable {
  const LiveRoundState({
    required this.window,
    this.status = LiveRoundStatus.loading,
    this.entry,
    this.players = const {},
    this.statusFor = const {},
  });

  final WeekWindow window; // الجولة اللي بتتلعب
  final LiveRoundStatus status;
  final RoundEntry? entry; // null = معملتش تشكيلة للجولة دي
  final Map<String, Player> players;
  final Map<String, PlayStatus> statusFor;

  @override
  List<Object?> get props => [window, status, entry, players, statusFor];
}
