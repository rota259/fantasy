import 'package:fantasy_5omasi/features/integrity/data/models/match_flags.dart';
import 'package:fantasy_5omasi/features/integrity/data/models/review_case.dart';
import 'package:fantasy_5omasi/features/matches/data/models/game_match.dart';
import 'package:fantasy_5omasi/features/pick/data/models/pick.dart';
import 'package:fantasy_5omasi/features/points/cubit/my_points_cubit.dart';
import 'package:fantasy_5omasi/features/points/data/player_round_points.dart';
import 'package:fantasy_5omasi/features/points/lineup_points.dart';
import 'package:fantasy_5omasi/features/week/data/week_window.dart';
import 'package:flutter_test/flutter_test.dart';

GameMatch _m(String id, String review, {String status = 'finished'}) => GameMatch.fromMap({
  'id': id,
  'date_time': '2026-09-20T18:00:00Z',
  'teams': ['A', 'B'],
  'week': 1,
  'status': status,
  'review_status': review,
  'flags': ['late_edit'],
});

/// جولة فيها [live] أهداف مباشر، منهم [approved] في ماتشات معتمدة (الجول = ٥).
RoundEntry _entry(int live, int approved) {
  const picks = [Pick(playerId: 'f', status: 'starting')];
  final pts = {
    'f': PlayerRoundPoints(
      playerId: 'f',
      points: live * 5,
      finalPoints: approved * 5,
      played: live > 0,
      playedFinal: approved > 0,
    ),
  };
  return (
    window: WeekWindow(DateTime(2026, 9, 26, 8)),
    picks: picks,
    chip: null,
    points: LineupPoints.compute(picks: picks, points: pts),
    finalPoints: LineupPoints.compute(picks: picks, points: pts, approvedOnly: true),
  );
}

void main() {
  test('حالة الاعتماد بتتقري من السيرفر', () {
    final m = _m('1', 'pending');
    expect(m.isProvisional, isTrue);
    expect(m.isApproved, isFalse);
    expect(m.flags, ['late_edit']);
    expect(_m('2', 'disputed').isProvisional, isTrue);
    expect(_m('3', 'void').isVoid, isTrue);
    // الماتشات القديمة (من غير العمود) = open ومش مبدئية
    expect(GameMatch.fromMap({'id': 'x', 'date_time': '2026-09-20T18:00:00Z'}).reviewStatus, 'open');
  });

  test('الإجمالي = المعتمد بس، والباقي مبدئي', () {
    final s = MyPointsState(
      entries: [_entry(1, 1), _entry(3, 1)], // ١٠ معتمد · ٢٠ مباشر
      bonuses: [_m('a', 'approved'), _m('p', 'pending')],
    );
    expect(s.total, 5 + 5 + MyPointsState.predictionBonus);
    expect(s.provisional, 10 + MyPointsState.predictionBonus);
  });

  test('طابور المراجعة بيقرا آراء اللاعيبة', () {
    final c = ReviewCase.fromMap({
      'id': 'm',
      'date_time': '2026-09-20T18:00:00Z',
      'teams': ['A', 'B'],
      'review_status': 'disputed',
      'flags': <String>[],
      'organizer_name': 'كريم',
      'reviews': [
        {'name': 'علي', 'team': 'A', 'ok': true, 'note': null},
        {'name': 'عمر', 'team': 'B', 'ok': false, 'note': 'الجول التاني مش صح'},
      ],
    });
    expect(c.isDisputed, isTrue);
    expect(c.match.isFinished, isTrue);
    expect(c.votes.where((v) => !v.ok).single.note, 'الجول التاني مش صح');
  });

  test('كل علامة ليها وصف عربي', () {
    for (final f in ['score_mismatch', 'big_margin', 'organizer_stats', 'new_organizer', 'late_edit']) {
      expect(MatchFlags.label(f), isNot(f));
    }
  });
}
