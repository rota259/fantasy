import 'package:fantasy_5omasi/features/week/data/models/totw_candidates.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _p(String id, int pts, [String pos = 'FWD']) => {
  'id': id,
  'name': id,
  'team': 'A',
  'position': pos,
  'points': pts,
};

void main() {
  test('الاقتراح = أعلى حارس + أعلى ٤ (الحارس التاني برا حتى لو نقطه أعلى)', () {
    final z = TotwCandidates.fromMap({
      'zone_id': 7,
      'zone_label': 'بدر · القاهرة',
      'candidates': [
        _p('a', 20),
        _p('g1', 18, 'GK'),
        _p('g2', 16, 'GK'),
        _p('b', 15),
        _p('c', 12),
        _p('d', 10),
        _p('e', 9),
      ],
    });
    expect(z.suggested, ['g1', 'a', 'b', 'c', 'd']);
  });

  test('تعادل على آخر مكان من الأربعة: فايزين تصويت اليوزرز بياخدوا الأماكن', () {
    final z = TotwCandidates.fromMap({
      'zone_id': 7,
      'zone_label': 'بدر',
      'candidates': [_p('g', 8, 'GK'), _p('a', 20), _p('b', 15), _p('d', 9), _p('e', 9), _p('f', 9)],
      'slots': 2,
      'tie_open': false,
      'tie_winners': ['f', 'd'],
    });
    expect(z.suggested, ['g', 'a', 'b', 'f', 'd']);
    expect(z.published, isFalse);
  });
}
