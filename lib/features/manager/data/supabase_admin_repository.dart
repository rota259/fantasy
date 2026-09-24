import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/models/app_user.dart';
import 'admin_repository.dart';

/// تنفيذ AdminRepository فوق profiles / picks / notifications + دالة notify-match.
class SupabaseAdminRepository implements AdminRepository {
  @override
  Future<List<AppUser>> fetchUsers() async {
    final rows = await SupabaseService.table('profiles')
        .select()
        .order('total_points', ascending: false);
    return rows.map(AppUser.fromMap).toList();
  }

  @override
  Future<void> setRole(String userId, String role) async {
    await SupabaseService.client.rpc('set_user_role', params: {'uid': userId, 'new_role': role});
  }

  @override
  Future<Set<String>> pickedUserIds(String matchId) async {
    final rows = await SupabaseService.table('picks').select('user_id').eq('match_id', matchId);
    return {for (final r in rows) r['user_id'].toString()};
  }

  @override
  Future<bool> notify({
    required String title,
    required String body,
    String kind = 'event',
    String? matchId,
    List<String>? userIds,
  }) async {
    // جوه التطبيق: صف واحد للكل، أو صف لكل يوزر متحدّد.
    final targets = (userIds == null || userIds.isEmpty) ? <String?>[null] : userIds;
    await SupabaseService.table('notifications').insert([
      for (final uid in targets)
        {'title': title, 'body': body, 'kind': kind, 'match_id': matchId, 'user_id': uid},
    ]);
    // push
    try {
      await SupabaseService.client.functions.invoke('notify-match', body: {
        'title': title,
        'body': body,
        if (matchId != null) 'match_id': matchId,
        if (userIds != null && userIds.isNotEmpty) 'user_ids': userIds,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
