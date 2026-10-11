import '../../../core/supabase/supabase_service.dart';
import '../../../core/zone/zone_scope.dart';
import '../../matches/data/models/game_match.dart';
import 'challenge_repository.dart';
import 'models/challenge_extras.dart';
import 'models/prediction.dart';

/// تنفيذ ChallengeRepository فوق matches.is_challenge (منطقتي بس) + جدول predictions.
class SupabaseChallengeRepository implements ChallengeRepository {
  @override
  Future<List<GameMatch>> challenges() async {
    final zone = ZoneScope.current;
    if (zone == null) return const [];
    final since = DateTime.now().subtract(const Duration(days: 7)).toUtc().toIso8601String();
    final rows = await SupabaseService.table(
      'matches',
    ).select().eq('is_challenge', true).eq('zone_id', zone).gte('date_time', since).order('date_time').limit(10);
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<Map<String, Prediction>> mine(List<String> matchIds, String userId) async {
    if (matchIds.isEmpty) return const {};
    final rows = await SupabaseService.table(
      'predictions',
    ).select().eq('user_id', userId).inFilter('match_id', matchIds);
    return {for (final r in rows) r['match_id'].toString(): Prediction.fromMap(r)};
  }

  @override
  Future<void> predict(String matchId, String userId, int scoreA, int scoreB) async {
    await SupabaseService.table('predictions').upsert({
      'match_id': matchId,
      'user_id': userId,
      'score_a': scoreA,
      'score_b': scoreB,
    }, onConflict: 'user_id,match_id');
  }

  @override
  Future<({int total, int correct})> summary(String matchId) async {
    final rows = await SupabaseService.client.rpc('challenge_summary', params: {'p_match': matchId}) as List;
    if (rows.isEmpty) return (total: 0, correct: 0);
    final r = rows.first as Map<String, dynamic>;
    return (total: (r['total'] as num).toInt(), correct: (r['correct'] as num).toInt());
  }

  @override
  Future<List<ChallengeWin>> wonMatches() async {
    final rows = await SupabaseService.client.rpc('my_challenge_wins') as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        (match: GameMatch.fromMap(r), points: (r['bonus'] as num?)?.toInt() ?? 0),
    ];
  }

  @override
  Future<({int streak, Map<String, ChallengeExtras> byMatch})> board() async {
    final b = await SupabaseService.client.rpc('challenge_board') as Map<String, dynamic>;
    return (
      streak: (b['streak'] as num?)?.toInt() ?? 0,
      byMatch: {
        for (final it in ((b['items'] as List?) ?? const []).cast<Map<String, dynamic>>())
          it['match_id'].toString(): ChallengeExtras.fromMap(it),
      },
    );
  }

  @override
  Future<void> answer(String matchId, ChallengeAnswers a) async {
    await SupabaseService.client.rpc(
      'answer_challenge',
      params: {
        'p_match': matchId,
        'p_duel': a.duel,
        'p_winner': a.winner,
        'p_over': a.over,
        'p_first': a.first,
        'p_lowest': a.lowest,
      },
    );
  }

  @override
  Future<void> setChallenge(
    String matchId, {
    List<String> modes = const [ChallengeMode.diff],
    String? duelA,
    String? duelB,
  }) async {
    await SupabaseService.client.rpc(
      'set_challenge',
      params: {'p_match': matchId, 'p_modes': modes, 'p_duel_a': duelA, 'p_duel_b': duelB},
    );
  }
}
