import 'package:fantasy_5omasi/features/week/data/models/week_player.dart';
import 'package:fantasy_5omasi/features/week/data/team_of_week.dart';
import 'package:flutter_test/flutter_test.dart';

WeekPlayer _w(String id, int pts, [String pos = 'FWD']) =>
    WeekPlayer(id: id, name: id, team: 'A', position: pos, points: pts);

void main() {
  test('أعلى ٥ نقط من أي مركز', () {
    final t = TeamOfWeek.build([_w('a', 20), _w('b', 15), _w('c', 12), _w('d', 9), _w('e', 8), _w('f', 7)]);
    expect(t.hasTie, isFalse);
    expect(t.lineup().map((p) => p?.id), ['a', 'b', 'c', 'd', 'e']);
  });

  test('تعادل على آخر مكان → المتعادلين للتصويت والمكان فاضي لحد ما يتحسم', () {
    final t = TeamOfWeek.build([_w('a', 20), _w('b', 15), _w('c', 12), _w('d', 9), _w('e', 8), _w('f', 8)]);
    expect(t.hasTie, isTrue);
    expect(t.openSlots, 1);
    expect(t.tied.map((p) => p.id), ['e', 'f']);
    expect(t.lineup().map((p) => p?.id), ['a', 'b', 'c', 'd', null]);
    expect(t.lineup(winnerIds: ['f']).map((p) => p?.id), ['a', 'b', 'c', 'd', 'f']);
  });

  test('تعادل على أكتر من مكان', () {
    final t = TeamOfWeek.build([_w('a', 20), _w('b', 15), _w('c', 9), _w('d', 9), _w('e', 9), _w('f', 9)]);
    expect(t.openSlots, 3);
    expect(t.tied.length, 4);
    expect(t.lineup(winnerIds: ['f', 'c', 'x']).map((p) => p?.id), ['a', 'b', 'f', 'c', null]);
  });

  test('أقل من ٥ جابوا نقط + السالب مش بيدخل', () {
    final t = TeamOfWeek.build([_w('a', 5), _w('b', -1), _w('c', 0)]);
    expect(t.lineup().map((p) => p?.id), ['a']);
  });

  test('الحارس تحت والأعلى نقط فوق', () {
    final spots = TeamOfWeek.arrange([_w('a', 20), _w('g', 15, 'GK'), _w('c', 12), _w('d', 9), _w('e', 8)]);
    expect(spots.map((p) => p?.id), ['g', 'a', 'c', 'd', 'e']);
  });
}
