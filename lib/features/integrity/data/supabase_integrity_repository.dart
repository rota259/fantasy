import '../../../core/supabase/supabase_service.dart';
import 'integrity_repository.dart';
import 'models/organizer_request.dart';
import 'models/pending_review.dart';
import 'models/review_case.dart';

/// تنفيذ IntegrityRepository فوق دوال السيرفر (قسم 21 في migrate_all.sql).
class SupabaseIntegrityRepository implements IntegrityRepository {
  static Future<List<Map<String, dynamic>>> _rpc(String fn) async {
    final rows = await SupabaseService.client.rpc(fn) as List;
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<PendingReview>> myPendingReviews() async =>
      (await _rpc('my_pending_reviews')).map(PendingReview.fromMap).toList();

  @override
  Future<String> reviewMatch(String matchId, {required bool ok, String? note}) async {
    final r = await SupabaseService.client.rpc(
      'review_match',
      params: {'p_match': matchId, 'p_ok': ok, 'p_note': note},
    );
    return r.toString();
  }

  @override
  Future<List<ReviewCase>> reviewQueue() async => (await _rpc('admin_review_queue')).map(ReviewCase.fromMap).toList();

  @override
  Future<void> resolve(String matchId, String action) async {
    await SupabaseService.client.rpc('resolve_match', params: {'p_match': matchId, 'p_action': action});
  }

  @override
  Future<void> notifyLineup(String matchId) async {
    await SupabaseService.client.rpc('notify_lineup', params: {'p_match': matchId});
  }

  @override
  Future<OrganizerRequest?> myOrganizerRequest(String userId) async {
    final rows = await SupabaseService.table(
      'organizer_requests',
    ).select().eq('user_id', userId).order('created_at', ascending: false).limit(1);
    return rows.isEmpty ? null : OrganizerRequest.fromMap(rows.first);
  }

  @override
  Future<void> requestOrganizer(String userId, String? note) async {
    await SupabaseService.table(
      'organizer_requests',
    ).insert({'user_id': userId, if (note != null && note.trim().isNotEmpty) 'note': note.trim()});
  }

  @override
  Future<List<OrganizerRequest>> pendingOrganizerRequests() async =>
      (await _rpc('pending_organizer_requests')).map(OrganizerRequest.fromMap).toList();

  @override
  Future<void> reviewOrganizerRequest(String requestId, bool approve) async {
    await SupabaseService.client.rpc('review_organizer_request', params: {'p_req': requestId, 'p_approve': approve});
  }
}
