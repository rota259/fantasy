import 'package:fantasy_5omasi/features/coach/coach_engine.dart';
import 'package:fantasy_5omasi/features/players/data/models/player.dart';
import 'package:fantasy_5omasi/features/players/data/models/player_gw_stat.dart';
import 'package:flutter_test/flutter_test.dart';

Player _p(String id, String team, {double form = 0, int total = 0, String avail = 'ready'}) => Player(
  id: id,
  name: 'P$id',
  team: team,
  position: 'MID',
  price: 0,
  form: form,
  totalPoints: total,
  availability: avail,
);

void main() {
  test('الكابتن = أعلى فورمة من لاعيبة الماتش الجاي والجاهزين بس', () {
    final r = CoachEngine.build(
      players: [
        _p('1', 'A', form: 9, avail: 'injured'), // مصاب → مستبعد
        _p('2', 'C', form: 8), // مش في الماتش الجاي → مستبعد
        _p('3', 'A', form: 5),
        _p('4', 'B', form: 7),
      ],
      stats: const {},
      nextTeams: const ['A', 'B'],
    );
    expect(r.captain?.id, '4');
  });

  test('مفيش داتا → مفيش كابتن ولا أقسام غير التجنّب', () {
    final r = CoachEngine.build(players: [_p('1', 'A')], stats: const {});
    expect(r.captain, isNull);
    expect(r.sections, isEmpty);
  });

  test('قسم التجنّب فيه المصابين والامتلاك بيترتّب صح', () {
    final r = CoachEngine.build(
      players: [
        _p('1', 'A', avail: 'injured'),
        _p('2', 'A'),
        _p('3', 'A'),
      ],
      stats: const {
        '2': PlayerGwStat(playerId: '2', ownership: 40),
        '3': PlayerGwStat(playerId: '3', ownership: 70),
      },
    );
    final avoid = r.sections.firstWhere((s) => s.title.startsWith('تجنّب'));
    expect(avoid.items.single.player.id, '1');
    final owned = r.sections.firstWhere((s) => s.title.startsWith('الأكثر امتلاكًا'));
    expect(owned.items.map((i) => i.player.id).toList(), ['3', '2']);
  });
}
