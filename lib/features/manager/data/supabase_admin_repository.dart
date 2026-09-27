import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/models/app_user.dart';
import 'admin_repository.dart';
import 'models/admin_log_entry.dart';

/// تنفيذ AdminRepository فوق admin_users / set_user_role / round_picks / notifications.
/// الـ push بيتبعت أوتوماتيك من الداتابيز لأي إشعار بيتسجّل (Edge Function push).
class SupabaseAdminRepository implements AdminRepository {
  @override
  Future<List<AppUser>> fetchUsers({String? query, String? role, int limit = 100}) async {
    // الإيميل والموبايل مخفيين عن اليوزرز — الأدمن بياخدهم من دالة admin_users (البحث في السيرفر)
    final rows =
        await SupabaseService.client.rpc('admin_users', params: {'p_query': query, 'p_role': role, 'p_limit': limit})
            as List;
    return rows.map((r) => AppUser.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<AdminCounts> counts() async {
    final r = ((await SupabaseService.client.rpc('admin_counts')) as List).first as Map<String, dynamic>;
    int n(String k) => (r[k] as num?)?.toInt() ?? 0;
    return (
      users: n('users'),
      admins: n('admins'),
      managers: n('managers'),
      players: n('players'),
      upcoming: n('upcoming'),
      finished: n('finished'),
    );
  }

  @override
  Future<void> setRole(String userId, String role) async {
    await SupabaseService.client.rpc('set_user_role', params: {'uid': userId, 'new_role': role});
  }

  @override
  Future<void> setActive(String userId, bool active) async {
    await SupabaseService.client.rpc('set_user_active', params: {'p_user': userId, 'p_active': active});
  }

  @override
  Future<void> setZone(String userId, int zoneId) async {
    await SupabaseService.client.rpc('admin_set_zone', params: {'p_user': userId, 'p_zone': zoneId});
  }

  @override
  Future<List<AdminLogEntry>> log() async {
    final rows = await SupabaseService.client.rpc('admin_log_list', params: {'p_limit': 150}) as List;
    return rows.map((r) => AdminLogEntry.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<int> roundPickerCount(DateTime roundEnd) => SupabaseService.table(
    'round_picks',
  ).count().eq('round_end', roundEnd.toUtc().toIso8601String()).eq('is_captain', true);

  @override
  Future<void> remindRound(String matchId) async {
    await SupabaseService.client.rpc('remind_round', params: {'p_match': matchId});
  }

  @override
  Future<void> notify({
    required String title,
    required String body,
    String kind = 'event',
    String? matchId,
    List<String>? userIds,
  }) async {
    // صف واحد للكل، أو صف لكل يوزر متحدّد (بيوصله هو بس).
    final targets = (userIds == null || userIds.isEmpty) ? <String?>[null] : userIds;
    await SupabaseService.table('notifications').insert([
      for (final uid in targets) {'title': title, 'body': body, 'kind': kind, 'match_id': matchId, 'user_id': uid},
    ]);
  }
}
