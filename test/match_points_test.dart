import 'package:fantasy_5omasi/features/events/data/models/match_event.dart';
import 'package:fantasy_5omasi/features/pick/data/models/pick.dart';
import 'package:fantasy_5omasi/features/players/data/models/player.dart';
import 'package:fantasy_5omasi/features/points/match_points.dart';
import 'package:flutter_test/flutter_test.dart';

Player _pl(String id, String pos) => Player(id: id, name: id, team: 'A', position: pos, price: 0);
MatchEvent _ev(String player, String type) =>
    MatchEvent(id: '$player$type', matchId: 'm', playerId: player, type: type);

void main() {
  final players = {'gk': _pl('gk', 'GK'), 'f1': _pl('f1', 'FWD'), 'm1': _pl('m1', 'MID'), 'b1': _pl('b1', 'FWD')};

  test('الكابتن اللي لعب بيتضاعف والاحتياطي مش بيتحسب', () {
    final r = MatchPoints.compute(
      picks: const [
        Pick(playerId: 'f1', status: 'starting', isCaptain: true),
        Pick(playerId: 'm1', status: 'starting', isVice: true),
        Pick(playerId: 'b1', status: 'bench'),
      ],
      events: [_ev('f1', 'goal'), _ev('m1', 'assist'), _ev('b1', 'goal')],
      players: players,
    );
    expect(r.of('f1')!.total, 8); // جول مهاجم 4 × 2
    expect(r.of('m1')!.total, 3); // النائب عادي لأن الكابتن لعب
    expect(r.of('b1')!.total, 0); // احتياطي
    expect(r.total, 11);
  });

  test('الكابتن ملعبش → النائب ياخد ×2', () {
    final r = MatchPoints.compute(
      picks: const [
        Pick(playerId: 'f1', status: 'starting', isCaptain: true),
        Pick(playerId: 'gk', status: 'starting', isVice: true),
      ],
      events: [_ev('gk', 'cleanSheet'), _ev('gk', 'save')],
      players: players,
    );
    expect(r.of('f1')!.total, 0);
    expect(r.of('gk')!.multiplier, 2);
    expect(r.total, 10); // (4 + 1) × 2
  });
}
