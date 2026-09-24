import '../../../core/supabase/supabase_service.dart';
import 'models/pick.dart';
import 'picks_repository.dart';

/// تنفيذ PicksRepository فوق جدول picks.
class SupabasePicksRepository implements PicksRepository {
  static const _table = 'picks';

  @override
  Future<List<Pick>> fetchForUserMatch(String userId, String matchId) async {
    final rows = await SupabaseService.table(_table)
        .select()
        .eq('user_id', userId)
        .eq('match_id', matchId);
    return rows.map(Pick.fromMap).toList();
  }

  @override
  Future<Map<String, List<Pick>>> fetchAllForUser(String userId) async {
    final rows = await SupabaseService.table(_table).select().eq('user_id', userId);
    final byMatch = <String, List<Pick>>{};
    for (final r in rows) {
      byMatch.putIfAbsent(r['match_id'].toString(), () => []).add(Pick.fromMap(r));
    }
    return byMatch;
  }

  @override
  Future<void> savePicks(String userId, String matchId, List<Pick> picks) async {
    // نمسح القديم ونكتب الجديد (استبدال كامل).
    await SupabaseService.table(_table)
        .delete()
        .eq('user_id', userId)
        .eq('match_id', matchId);
    if (picks.isEmpty) return;
    await SupabaseService.table(_table).insert([
      for (final p in picks)
        {
          'user_id': userId,
          'match_id': matchId,
          'player_id': p.playerId,
          'status': p.status,
          'is_captain': p.isCaptain,
          'is_vice': p.isVice,
        },
    ]);
  }
}
