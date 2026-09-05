import 'package:flutter_test/flutter_test.dart';
import 'package:fantasy_5omasi/features/points/points_engine.dart';
import 'package:fantasy_5omasi/features/players/data/models/player.dart';
import 'package:fantasy_5omasi/features/events/data/models/match_event.dart';

Player _p(String id, String pos) =>
    Player(id: id, name: 'لاعب $id', team: 'ت', position: pos, price: 5);

MatchEvent _e(String playerId, String type) =>
    MatchEvent(id: 'e$playerId$type', matchId: 'm1', playerId: playerId, type: type);

void main() {
  group('eventPoints — النقاط حسب النوع والمركز', () {
    test('الجول بيختلف حسب المركز', () {
      expect(PointsEngine.eventPoints('goal', 'GK'), 6);
      expect(PointsEngine.eventPoints('goal', 'DEF'), 6);
      expect(PointsEngine.eventPoints('goal', 'MID'), 5);
      expect(PointsEngine.eventPoints('goal', 'FWD'), 4);
    });

    test('الشباك النظيفة للدفاع بس', () {
      expect(PointsEngine.eventPoints('cleanSheet', 'DEF'), 4);
      expect(PointsEngine.eventPoints('cleanSheet', 'MID'), 1);
      expect(PointsEngine.eventPoints('cleanSheet', 'FWD'), 0);
    });

    test('الأسيست ثابت والكروت بالسالب', () {
      expect(PointsEngine.eventPoints('assist', 'FWD'), 3);
      expect(PointsEngine.eventPoints('yellowCard', 'MID'), -1);
      expect(PointsEngine.eventPoints('redCard', 'DEF'), -3);
    });

    test('نوع غير معروف = صفر', () {
      expect(PointsEngine.eventPoints('whatever', 'FWD'), 0);
    });
  });

  test('playerPoints بيجمع أحداث اللاعب', () {
    final events = [_e('1', 'goal'), _e('1', 'assist'), _e('1', 'yellowCard')];
    // مهاجم: 4 + 3 - 1 = 6
    expect(PointsEngine.playerPoints('FWD', events), 6);
  });

  test('squadPoints بيضاعف نقاط الكابتن', () {
    final squad = [_p('1', 'FWD'), _p('2', 'DEF')];
    final events = [_e('1', 'goal'), _e('2', 'cleanSheet')];
    // بدون كابتن: 4 + 4 = 8
    expect(PointsEngine.squadPoints(squad, null, events), 8);
    // الكابتن اللاعب 1 (مهاجم، جول 4 ×2 = 8) + 4 = 12
    expect(PointsEngine.squadPoints(squad, '1', events), 12);
  });
}
