import 'package:fantasy_5omasi/core/zone/zone_scope.dart';
import 'package:fantasy_5omasi/features/auth/data/models/app_user.dart';
import 'package:fantasy_5omasi/features/teams/data/team.dart';
import 'package:fantasy_5omasi/features/zones/data/zone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => ZoneScope.current = null);

  test('المنطقة بتتقري واسمها بالمحافظة', () {
    final z = Zone.fromMap({'id': 7, 'governorate': 'القاهرة', 'name': 'بدر'});
    expect(z.id, 7);
    expect(z.label, 'بدر · القاهرة');
  });

  test('الفلتر: منطقتي بس، ومن غير منطقة مفيش فلتر', () {
    expect(ZoneScope.orFilter, isNull);
    ZoneScope.current = 7;
    expect(ZoneScope.orFilter, 'zone_id.eq.7');
  });

  test('منطقة اليوزر بتتقري وبتتبعت مع التسجيل', () {
    final u = AppUser.fromMap({'id': 'u', 'name': 'علي', 'email': 'a@b.c', 'zone_id': 7});
    expect(u.zoneId, 7);
    expect(u.toInsert()['zone_id'], 7);
    expect(AppUser.fromMap({'id': 'u'}).zoneId, isNull); // حساب قديم → لازم يختار
  });

  test('الفريق بصاحبه ومنطقته', () {
    final t = Team.fromMap({
      'id': 't',
      'name': 'نسور بدر',
      'zone_id': 7,
      'owner_id': 'o',
      'owner': {'name': 'كريم'},
    });
    expect((t.zoneId, t.ownerId, t.ownerName), (7, 'o', 'كريم'));
    expect(Team.fromMap({'id': 't', 'name': 'قديم'}).zoneId, isNull);
  });
}
