import '../../../core/supabase/supabase_service.dart';
import '../../matches/data/models/game_match.dart';
import 'challenge_repository.dart';
import 'models/prediction.dart';

/// تنفيذ ChallengeRepository فوق matches.is_challenge + جدول predictions.
class SupabaseChallengeRepository implements ChallengeRepository {
  @override
  Future<GameMatch?> current() async {
    final next = await SupabaseService.table(
      'matches',
    ).select().eq('is_challenge', true).eq('status', 'upcoming').order('date_time').limit(1);
    if (next.isNotEmpty) return GameMatch.fromMap(next.first);
    final last = await SupabaseService.table(
      'matches',
    ).select().eq('is_challenge', true).order('date_time', ascending: false).limit(1);
    return last.isEmpty ? null : GameMatch.fromMap(last.first);
  }

  @override
  Future<Prediction?> mine(String matchId, String userId) async {
    final row = await SupabaseService.table(
      'predictions',
    ).select().eq('match_id', matchId).eq('user_id', userId).maybeSingle();
    return row == null ? null : Prediction.fromMap(row);
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
            when m.scoreA == r['score_a'] && m.scoreB == r['score_b'])
          m,
    ];
  }

  @override
  Future<void> setChallenge(String matchId) async {
    await SupabaseService.client.rpc('set_challenge', params: {'p_match': matchId});
  }
}
