import 'package:fantasy_5omasi/features/events/data/models/match_event.dart';
import 'package:fantasy_5omasi/features/matches/match_live.dart';
import 'package:flutter_test/flutter_test.dart';

MatchEvent _e(String id, String type, String player, {String? other, int? minute}) =>
    MatchEvent(id: id, matchId: 'm', playerId: player, type: type, minute: minute, otherPlayerId: other);

void main() {
  const lineup = {'a1': 'starting', 'a2': 'starting', 'a3': 'bench', 'b1': 'starting', 'b2': 'bench'};

  test('في الملعب: الأساسيين + اللي نزل − اللي طلع − الأحمر', () {
    final events = [_e('1', 'sub', 'a3', other: 'a1', minute: 20), _e('2', 'redCard', 'b1', minute: 25)];
    expect(MatchLive.onPitch(lineup, events), {'a2', 'a3'});
    expect(MatchLive.benchLeft(lineup, events), {'b2'});
  });

  test('النتيجة من الأهداف والجول العكسي للفريق التاني', () {
    const teamOf = {'a1': 'نسور', 'b1': 'صقور'};
    final events = [_e('1', 'goal', 'a1'), _e('2', 'goal', 'a1'), _e('3', 'ownGoal', 'a1'), _e('4', 'assist', 'b1')];
    expect(MatchLive.score(['نسور', 'صقور'], events, teamOf), (a: 2, b: 1));
  });

  test('التايملاين بالدقيقة', () {
    final t = MatchLive.timeline([
      _e('1', 'goal', 'a1', minute: 30),
      _e('2', 'goal', 'b1', minute: 5),
      _e('3', 'save', 'b1'),
    ]);
    expect(t.map((e) => e.id), ['2', '1', '3']);
  });

  test('الملخص: هاتريك = الاسم مرة و٣ كور، والأحداث المختلفة كل واحد في سطر', () {
    final g = MatchLive.grouped([
      _e('1', 'goal', 'a1', minute: 12),
      _e('2', 'yellowCard', 'a1', minute: 20),
      _e('3', 'goal', 'b1', minute: 25),
      _e('4', 'goal', 'a1', minute: 30),
      _e('5', 'goal', 'a1', minute: 44),
    ]);
    expect(g.map((x) => '${x.type}:${x.playerId}:${x.minutes.length}'), ['goal:a1:3', 'yellowCard:a1:1', 'goal:b1:1']);
    expect(g.first.minutes, [12, 30, 44]);
  });
}
