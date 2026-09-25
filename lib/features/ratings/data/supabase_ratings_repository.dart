import '../../../core/supabase/supabase_service.dart';
import 'models/player_rating.dart';
import 'ratings_repository.dart';

/// تنفيذ RatingsRepository فوق جدول player_ratings + دالة match_rating_summary.
class SupabaseRatingsRepository implements RatingsRepository {
  @override
  Future<List<PlayerRating>> summary(String matchId) async {
    final rows = await SupabaseService.client.rpc('match_rating_summary', params: {'p_match': matchId}) as List;
    return rows.map((r) => PlayerRating.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> rate(String matchId, String playerId, String userId, int rating) async {
    await SupabaseService.table('player_ratings').upsert({
      'match_id': matchId,
      'player_id': playerId,
      'user_id': userId,
      'rating': rating,
    }, onConflict: 'match_id,player_id,user_id');
  }
}
