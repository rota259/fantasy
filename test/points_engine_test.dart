import 'package:fantasy_5omasi/features/points/points_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('الجول: الحارس ٨ وأي حد تاني ٥', () {
    expect(PointsEngine.eventPoints('goal', 'GK'), 8);
    expect(PointsEngine.eventPoints('goal', 'DEF'), 5);
    expect(PointsEngine.eventPoints('goal', 'FWD'), 5);
  });

  test('الخصومات بالسالب', () {
    expect(PointsEngine.eventPoints('penaltyMiss', 'FWD'), -3);
    expect(PointsEngine.eventPoints('insult', 'MID'), -5);
    expect(PointsEngine.eventPoints('ownGoal', 'DEF'), -2);
  });

  test('التصدّي والتدخّل قيمتهم بتتحسب بالمجموع (مش لوحدهم)', () {
    expect(PointsEngine.eventPoints('save', 'GK'), 0);
    expect(PointsEngine.eventPoints('tackle', 'DEF'), 0);
  });

  test('المدير بيسجّل الأحداث الجديدة (والقديمة مش موجودة)', () {
    final types = PointsEngine.managerEvents.map((e) => e.$1).toSet();
    expect(types, containsAll(['tackle', 'penaltySave', 'penaltyMiss', 'insult', 'ownGoal']));
    expect(types.intersection({'yellowCard', 'redCard', 'cleanSheet', 'bonus', 'appearance'}), isEmpty);
  });
}
