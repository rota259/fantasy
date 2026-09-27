import '../../../core/supabase/supabase_service.dart';
import '../../../core/zone/zone_scope.dart';
import '../../matches/data/models/game_match.dart';
import 'challenge_repository.dart';
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
  Future<List<GameMatch>> wonMatches(String userId) async {
    final rows = await SupabaseService.table('predictions')
        .select('score_a, score_b, matches!inner(*)')
        .eq('user_id', userId)
        .eq('matches.is_challenge', true)
        .eq('matches.status', 'finished');
    return [
      for (final r in rows)
        if (GameMatch.fromMap(r['matches'] as Map<String, dynamic>) case final m
            when Prediction.fromMap({...r, 'match_id': m.id}).matches(m.scoreA, m.scoreB))
          m,
    ];
  }

  @override
  Future<void> setChallenge(String matchId) async {
    await SupabaseService.client.rpc('set_challenge', params: {'p_match': matchId});
  }
}
