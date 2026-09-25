import '../../../core/supabase/supabase_service.dart';
import 'models/venue_review.dart';
import 'reviews_repository.dart';

/// تنفيذ ReviewsRepository فوق venue_reviews + دالة venue_review_list (بالأسماء).
class SupabaseReviewsRepository implements ReviewsRepository {
  static const _table = 'venue_reviews';

  @override
  Future<List<VenueReview>> list(String venueId) async {
    final rows = await SupabaseService.client.rpc('venue_review_list', params: {'p_venue': venueId}) as List;
    return rows.map((r) => VenueReview.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> save(String venueId, String userId, int stars, String? comment) async {
    final c = comment?.trim();
    await SupabaseService.table(_table).upsert({
      'venue_id': venueId,
      'user_id': userId,
      'stars': stars,
      'comment': (c == null || c.isEmpty) ? null : c,
    }, onConflict: 'venue_id,user_id');
  }

  @override
  Future<void> delete(String venueId, String userId) async {
    await SupabaseService.table(_table).delete().eq('venue_id', venueId).eq('user_id', userId);
  }
}
