import '../matches/data/models/game_match.dart';
import '../matches/widgets/match_format.dart';

/// حالة لاعب في جولة: لعب · بيلعب دلوقتي · لسه هيلعب · ملعبش.
enum PlayState { played, live, upcoming, didNotPlay, noMatch }

typedef PlayStatus = ({PlayState state, String label});

/// من ماتشات فريقه في الجولة + هل ليه أحداث/اتسجّل في تشكيلة ماتش ([played]).
PlayStatus playStatus(String team, List<GameMatch> roundMatches, {required bool played, DateTime? now}) {
  final n = now ?? DateTime.now();
  final mine = roundMatches.where((m) => m.teams.contains(team)).toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  if (mine.isEmpty) return (state: PlayState.noMatch, label: 'فريقه مالوش ماتش في الجولة');
  if (mine.any((m) => !m.isFinished && !m.dateTime.isAfter(n))) {
    return (state: PlayState.live, label: '🔴 بيلعب دلوقتي');
  }
  final next = mine.where((m) => !m.isFinished).firstOrNull;
  if (next != null) {
    final when = '${arabicWeekday(next.dateTime)} ${arabicTime(next.dateTime)}';
    return (state: PlayState.upcoming, label: played ? '✓ لعب · وليه ماتش كمان $when' : '⏳ لسه هيلعب · $when');
  }
  return played ? (state: PlayState.played, label: '✓ لعب') : (state: PlayState.didNotPlay, label: 'ملعبش');
}
