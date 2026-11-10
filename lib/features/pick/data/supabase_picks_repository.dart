import '../../../core/supabase/supabase_service.dart';
import 'models/pick.dart';
import 'models/round_locks.dart';
import 'picks_repository.dart';

/// تنفيذ PicksRepository فوق جدول round_picks + دالة save_round_picks.
class SupabasePicksRepository implements PicksRepository {
  static const _table = 'round_picks';

  static String _db(DateTime t) => t.toUtc().toIso8601String();

  @override
  Future<List<Pick>> fetchRound(String userId, DateTime roundEnd) async {
    final rows = await SupabaseService.table(_table).select().eq('user_id', userId).eq('round_end', _db(roundEnd));
    return rows.map(Pick.fromMap).toList();
  }

  @override
  Future<Map<DateTime, List<Pick>>> fetchAllRounds(String userId) async {
    final rows = await SupabaseService.table(_table).select().eq('user_id', userId);
    final byRound = <DateTime, List<Pick>>{};
    for (final r in rows) {
      final end = DateTime.parse(r['round_end'].toString()).toLocal();
      byRound.putIfAbsent(end, () => []).add(Pick.fromMap(r));
    }
    return byRound;
  }

  @override
  Future<RoundLocks> roundLocks(DateTime roundEnd) async => RoundLocks.fromMap(
    Map<String, dynamic>.from(
      await SupabaseService.client.rpc('my_round_state', params: {'p_round': _db(roundEnd)}) as Map,
    ),
  );

  @override
  Future<void> saveRound(DateTime roundEnd, List<Pick> picks) async {
    await SupabaseService.client.rpc(
      'save_round_picks',
      params: {
        'p_round': _db(roundEnd),
        'p_picks': [
          for (final p in picks)
            {'player_id': p.playerId, 'status': p.status, 'is_captain': p.isCaptain, 'is_vice': p.isVice},
        ],
      },
    );
  }
}
