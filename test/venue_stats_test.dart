import 'package:fantasy_5omasi/features/matches/data/models/match_place.dart';
import 'package:fantasy_5omasi/features/pitch/data/models/venue_extras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('إحصائيات الملعب: الأسطورة = أول واحد والساعات بأرقام', () {
    final s = VenueStats.fromMap({
      'matches': 4,
      'teams': 6,
      'goals': 19,
      'tournaments': 1,
      'hours': {'20': 3, '22': 1},
      'top': [
        {'id': 'p1', 'name': 'أحمد', 'nickname': 'حمو', 'team': 'الأسود', 'g': 7, 'a': 2, 'mp': 4},
        {'id': 'p2', 'name': 'كريم', 'team': 'النمور', 'g': 3, 'a': 1, 'mp': 2},
      ],
    });
    expect(s.legend?.label, 'أحمد (حمو)');
    expect(s.legend?.goals, 7);
    expect(s.hours[20], 3);
    expect(s.top.length, 2);
  });

  test('ملعب فاضي من غير ماتشات', () {
    final s = VenueStats.fromMap({'hours': {}, 'top': []});
    expect(s.legend, isNull);
    expect(s.matches, 0);
  });

  test('مكان الماتش: الاسم والعنوان، ومن غير اسم = مفيش مكان', () {
    final p = MatchPlace.fromMap({'venue_name': 'ملعب الحرية', 'venue_address': 'الحي التاني', 'venue_id': 'v1'});
    expect(p?.label, 'ملعب الحرية · الحي التاني');
    expect(p?.toWrite()['venue_id'], 'v1');
    expect(MatchPlace.fromMap({'venue_name': null}), isNull);
  });
}
