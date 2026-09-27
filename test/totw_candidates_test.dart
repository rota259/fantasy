import 'package:fantasy_5omasi/features/week/data/models/totw_candidates.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _p(String id, int pts) => {'id': id, 'name': id, 'team': 'A', 'position': 'FWD', 'points': pts};

void main() {
  test('الاقتراح = الأعلى ٥ نقط', () {
    final z = TotwCandidates.fromMap({
      'zone_id': 7,
      'zone_label': 'بدر · القاهرة',
      'candidates': [_p('a', 20), _p('b', 15), _p('c', 12), _p('d', 10), _p('e', 9), _p('f', 5)],
    });
    expect(z.suggested, ['a', 'b', 'c', 'd', 'e']);
  });

  test('تعادل على آخر مكان: فايزين تصويت اليوزرز بياخدوا الأماكن', () {
    final z = TotwCandidates.fromMap({
      'zone_id': 7,
      'zone_label': 'بدر',
      'candidates': [_p('a', 20), _p('b', 15), _p('c', 12), _p('d', 9), _p('e', 9), _p('f', 9)],
      'slots': 2,
      'tie_open': false,
      'tie_winners': ['f', 'd'],
    });
    expect(z.suggested, ['a', 'b', 'c', 'f', 'd']);
    expect(z.published, isFalse);
  });
}
