import 'package:fantasy_5omasi/features/matches/data/models/game_match.dart';
import 'package:fantasy_5omasi/features/points/play_status.dart';
import 'package:flutter_test/flutter_test.dart';

GameMatch _m(String id, DateTime at, {bool done = false}) =>
    GameMatch(id: id, dateTime: at, teams: const ['نسور', 'صقور'], week: 1, status: done ? 'finished' : 'upcoming');

void main() {
  final now = DateTime(2026, 9, 23, 20);

  test('فريقه مالوش ماتش', () {
    expect(playStatus('ديابة', [_m('1', now)], played: false, now: now).state, PlayState.noMatch);
  });

  test('الماتش بدأ ولسه مخلصش = بيلعب دلوقتي', () {
    final s = playStatus('نسور', [_m('1', now.subtract(const Duration(minutes: 20)))], played: true, now: now);
    expect(s.state, PlayState.live);
  });

  test('ماتش جاي = لسه هيلعب، ولو لعب قبله بيقول وليه ماتش كمان', () {
    final later = now.add(const Duration(days: 1));
    expect(playStatus('صقور', [_m('1', later)], played: false, now: now).state, PlayState.upcoming);
    final both = [_m('1', now.subtract(const Duration(days: 1)), done: true), _m('2', later)];
    expect(playStatus('صقور', both, played: true, now: now).label, startsWith('✓ لعب · وليه ماتش كمان'));
  });

  test('كل ماتشاته خلصت: لعب ولا ملعبش', () {
    final done = [_m('1', now.subtract(const Duration(days: 1)), done: true)];
    expect(playStatus('نسور', done, played: true, now: now).state, PlayState.played);
    expect(playStatus('نسور', done, played: false, now: now).state, PlayState.didNotPlay);
  });
}
