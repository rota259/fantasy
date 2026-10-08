import 'package:fantasy_5omasi/features/week/data/models/week_player.dart';
import 'package:fantasy_5omasi/features/week/data/team_of_week.dart';
import 'package:flutter_test/flutter_test.dart';

WeekPlayer _w(String id, int pts, [String pos = 'FWD']) =>
    WeekPlayer(id: id, name: id, team: 'A', position: pos, points: pts);

void main() {
  test('أعلى حارس + أعلى ٤ لاعيبة (مش أعلى ٥ والسلام)', () {
    final t = TeamOfWeek.build([
      _w('a', 20),
      _w('g1', 18, 'GK'),
      _w('g2', 16, 'GK'),
      _w('b', 15),
      _w('c', 12),
      _w('d', 9),
      _w('e', 8),
    ]);
    expect(t.hasTie, isFalse);
    expect(t.lineup().map((p) => p?.id), ['g1', 'a', 'b', 'c', 'd']); // g2 برا رغم نقطه
    expect(TeamOfWeek.starOf(t.lineup())?.id, 'a');
  });

  test('تعادل على آخر مكان من الأربعة → المتعادلين للتصويت والمكان فاضي لحد ما يتحسم', () {
    final t = TeamOfWeek.build([_w('g', 10, 'GK'), _w('a', 20), _w('b', 15), _w('c', 12), _w('d', 8), _w('e', 8)]);
    expect(t.hasTie, isTrue);
    expect(t.openSlots, 1);
    expect(t.tied.map((p) => p.id), ['d', 'e']);
    expect(t.lineup().map((p) => p?.id), ['g', 'a', 'b', 'c', null]);
    expect(t.lineup(winnerIds: ['e']).map((p) => p?.id), ['g', 'a', 'b', 'c', 'e']);
  });

  test('تعادل على أكتر من مكان', () {
    final t = TeamOfWeek.build([_w('g', 5, 'GK'), _w('a', 20), _w('c', 9), _w('d', 9), _w('e', 9), _w('f', 9)]);
    expect(t.openSlots, 3);
    expect(t.tied.length, 4);
    expect(t.lineup(winnerIds: ['f', 'c', 'x']).map((p) => p?.id), ['g', 'a', 'f', 'c', null]);
  });

  test('مفيش حارس جاب نقط + السالب مش بيدخل', () {
    final t = TeamOfWeek.build([_w('a', 5), _w('b', -1), _w('c', 0), _w('g', 0, 'GK')]);
    expect(t.lineup().map((p) => p?.id), ['a']);
  });

  test('الحارس تحت والأعلى نقط فوق', () {
    final spots = TeamOfWeek.arrange([_w('a', 20), _w('g', 15, 'GK'), _w('c', 12), _w('d', 9), _w('e', 8)]);
    expect(spots.map((p) => p?.id), ['g', 'a', 'c', 'd', 'e']);
  });
}
