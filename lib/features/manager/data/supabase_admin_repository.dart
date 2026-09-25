import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/models/app_user.dart';
import 'admin_repository.dart';

/// تنفيذ AdminRepository فوق admin_users / set_user_role / picks / notifications.
/// الـ push بيتبعت أوتوماتيك من الداتابيز لأي إشعار بيتسجّل (Edge Function push).
class SupabaseAdminRepository implements AdminRepository {
  @override
  Future<List<AppUser>> fetchUsers() async {
    // الإيميل والموبايل مخفيين عن اليوزرز — المدير بياخدهم من دالة admin_users
    final rows = await SupabaseService.client.rpc('admin_users') as List;
    return rows.map((r) => AppUser.fromMap(r as Map<String, dynamic>)).toList();
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
