import 'package:fantasy_5omasi/features/chips/data/chip_type.dart';
import 'package:fantasy_5omasi/features/pick/data/models/pick.dart';
import 'package:fantasy_5omasi/features/points/data/player_round_points.dart';
import 'package:fantasy_5omasi/features/points/lineup_points.dart';
import 'package:flutter_test/flutter_test.dart';

/// نقط لاعب جاية من السيرفر (المباشر والمعتمد).
PlayerRoundPoints _pts(String id, int live, {int? fin}) => PlayerRoundPoints(
  playerId: id,
  points: live,
  finalPoints: fin ?? live,
  played: true,
  playedFinal: fin == null || fin != 0,
);

void main() {
  const picks = [
    Pick(playerId: 'f1', status: 'starting', isCaptain: true),
    Pick(playerId: 'm1', status: 'starting', isVice: true),
    Pick(playerId: 'b1', status: 'bench'),
  ];
  final points = {'f1': _pts('f1', 5), 'm1': _pts('m1', 3), 'b1': _pts('b1', 5)};

  test('الكابتن اللي لعب بيتضاعف والاحتياطي مش بيتحسب', () {
    final r = LineupPoints.compute(picks: picks, points: points);
    expect(r.of('f1')!.total, 10); // جول ٥ × ٢
    expect(r.of('m1')!.total, 3); // البديل عادي لأن الكابتن لعب
    expect(r.of('b1')!.total, 0); // احتياطي
    expect(r.total, 13);
  });

  test('الكابتن ملعبش خالص → البديل ياخد ×٢', () {
    final r = LineupPoints.compute(picks: picks, points: {'m1': _pts('m1', 8)});
    expect(r.of('f1')!.total, 0);
    expect(r.of('m1')!.multiplier, 2);
    expect(r.total, 16);
  });

  test('المعتمد بس: ماتش الكابتن لسه مستني اعتماد → البديل بياخد المضاعفة في المعتمد', () {
    final r = LineupPoints.compute(
      picks: picks,
      points: {'f1': _pts('f1', 5, fin: 0), 'm1': _pts('m1', 3)},
      approvedOnly: true,
    );
    expect(r.of('f1')!.total, 0);
    expect(r.of('m1')!.total, 6);
  });

  group('الكروت', () {
    test('كابتن ×٣', () {
      final r = LineupPoints.compute(picks: picks, points: points, chip: ChipType.triple);
      expect(r.of('f1')!.total, 15);
      expect(r.total, 18);
    });

    test('الاحتياطي يتحسب', () {
      final r = LineupPoints.compute(picks: picks, points: points, chip: ChipType.benchBoost);
      expect(r.of('b1')!.total, 5);
      expect(r.total, 18);
    });

    test('الدبل ×٢ على المجموع كله', () {
      final r = LineupPoints.compute(picks: picks, points: points, chip: ChipType.doubleUp);
      expect(r.subtotal, 13);
      expect(r.total, 26);
    });
  });

  test('التفصيل بيتقري من السيرفر', () {
    final p = PlayerRoundPoints.fromMap({
      'player_id': 'f1',
      'points': 28,
      'final_points': 28,
      'played': true,
      'played_final': true,
      'items': [
        {'k': 'جول', 'n': 4, 'p': 22},
        {'k': 'بونص هاتريك أهداف', 'n': 1, 'p': 6},
      ],
    });
    expect(p.items.first, (label: 'جول', count: 4, points: 22));
    expect(p.items.fold(0, (s, i) => s + i.points), 28);
  });
}
