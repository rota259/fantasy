import 'package:fantasy_5omasi/features/week/cubit/team_of_week_cubit.dart';
import 'package:fantasy_5omasi/features/week/data/models/week_player.dart';
import 'package:fantasy_5omasi/features/week/data/week_window.dart';
import 'package:flutter_test/flutter_test.dart';

WeekPlayer _w(String id, String pos, int pts) => WeekPlayer(id: id, name: id, team: 'A', position: pos, points: pts);

void main() {
  test('تشكيلة الأسبوع: أحسن واحد في كل مركز + أحسن واحد فاضل من الملعب', () {
    final s = TeamOfWeekState(
      window: WeekWindow(DateTime(2026, 9, 25, 4)),
      players: [
        _w('f1', 'FWD', 20), _w('f2', 'FWD', 15), _w('m1', 'MID', 12),
        _w('g1', 'GK', 9), _w('d1', 'DEF', 7), _w('g2', 'GK', 8),
      ],
    );
    expect(s.lineup.map((p) => p?.id).toList(), ['g1', 'd1', 'm1', 'f1', 'f2']);
  });

  test('لو مفيش لاعب في مركز يفضل فاضي', () {
    final s = TeamOfWeekState(window: WeekWindow(DateTime(2026, 9, 25, 4)), players: [_w('f1', 'FWD', 5)]);
    expect(s.lineup.map((p) => p?.id).toList(), [null, null, null, 'f1', null]);
  });
}
