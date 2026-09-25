import '../../../core/supabase/supabase_service.dart';
import 'follows_repository.dart';

/// تنفيذ FollowsRepository فوق جدول match_follows (الحد بيتحقق في السيرفر).
class SupabaseFollowsRepository implements FollowsRepository {
  static const _table = 'match_follows';

  @override
  Future<Set<String>> mine(String userId) async {
    final rows = await SupabaseService.table(_table).select('match_id').eq('user_id', userId);
    return {for (final r in rows) r['match_id'].toString()};
  }

  @override
  Future<void> follow(String matchId, String userId) async {
    await SupabaseService.table(_table).insert({'match_id': matchId, 'user_id': userId});
  }

  @override
  Future<void> unfollow(String matchId, String userId) async {
    await SupabaseService.table(_table).delete().eq('match_id', matchId).eq('user_id', userId);
  }
}
