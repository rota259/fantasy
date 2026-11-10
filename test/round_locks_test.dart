import 'package:fantasy_5omasi/features/pick/data/models/round_locks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 15, 18);
  final locks = RoundLocks.fromMap({
    'locks': {
      'a': DateTime(2026, 10, 15, 17).toUtc().toIso8601String(),
      'b': DateTime(2026, 10, 16, 20).toIso8601String(),
    },
    'baseline': ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
    'wildcard': false,
    'free': 1,
    'hit': 4,
  });

  test('اللاعب بيتقفل قبل ماتشه بساعة (الميعاد من السيرفر) — واللي ملوش ماتش حر', () {
    expect(locks.isLocked('a', now), isTrue);
    expect(locks.isLocked('b', now), isFalse);
    expect(locks.isLocked('z', now), isFalse);
  });

  test('التغييرات = لاعيبة مكانوش في تشكيلة الجولة اللي فاتت', () {
    expect(locks.transfers(['a', 'b', 'c', 'd', 'e', 'f', 'g']), 0);
    expect(locks.transfers(['a', 'b', 'c', 'd', 'e', 'f', 'x']), 1);
    expect(locks.transfers(['a', 'b', 'c', 'd', 'e', 'y', 'x']), 2);
  });

  test('أول تغيير ببلاش وكل واحد زيادة −٤', () {
    expect(locks.cost(0), 0);
    expect(locks.cost(1), 0);
    expect(locks.cost(2), 4);
    expect(locks.cost(4), 12);
  });

  test('المجاني المتجمّع من السيرفر', () {
    final banked = RoundLocks.fromMap({
      'baseline': ['a'],
      'free': 3,
    });
    expect(banked.cost(3), 0);
    expect(banked.cost(5), 8);
  });

  test('الوايلد كارد وأول تشكيلة: ببلاش', () {
    expect(
      RoundLocks.fromMap({
        'wildcard': true,
        'baseline': ['a'],
      }).cost(5),
      0,
    );
    final first = RoundLocks.fromMap({'baseline': null});
    expect(first.transfers(['x', 'y']), 0);
  });
}
