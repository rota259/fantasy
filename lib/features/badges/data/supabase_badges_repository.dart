import '../../../core/supabase/supabase_service.dart';
import 'badges_repository.dart';
import 'models/user_badge.dart';

/// تنفيذ BadgesRepository فوق جدول user_badges.
class SupabaseBadgesRepository implements BadgesRepository {
  static const _table = 'user_badges';

  @override
  Future<List<UserBadge>> forUser(String userId) async {
    final rows = await SupabaseService.table(_table).select().eq('user_id', userId);
    return rows.map(UserBadge.fromMap).toList();
  }

  @override
  Future<Map<String, List<UserBadge>>> earnedFor(List<String> userIds) async {
    if (userIds.isEmpty) return const {};
    final rows = await SupabaseService.table(_table)
        .select()
        .inFilter('user_id', userIds)
        .gt('tier', 0)
        .order('tier', ascending: false)
        .order('earned_at', ascending: false);
    final out = <String, List<UserBadge>>{};
    for (final r in rows) {
      out.putIfAbsent(r['user_id'].toString(), () => []).add(UserBadge.fromMap(r));
    }
    return out;
  }
}
