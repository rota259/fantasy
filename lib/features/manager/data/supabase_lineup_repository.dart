import '../../../core/supabase/supabase_service.dart';
import 'lineup_repository.dart';
import 'models/lineup.dart';

/// تنفيذ LineupRepository فوق جدول lineups.
class SupabaseLineupRepository implements LineupRepository {
  static const _table = 'lineups';

  @override
  Future<List<Lineup>> fetchForMatch(String matchId) async {
    final rows =
        await SupabaseService.table(_table).select().eq('match_id', matchId);
    return rows.map(Lineup.fromMap).toList();
  }

  @override
  Future<void> setStatus(String matchId, String playerId, String status) async {
    await SupabaseService.table(_table).upsert(
      {'match_id': matchId, 'player_id': playerId, 'status': status},
      onConflict: 'match_id,player_id',
    );
  }

  @override
  Future<void> remove(String matchId, String playerId) async {
    await SupabaseService.table(_table)
        .delete()
        .eq('match_id', matchId)
        .eq('player_id', playerId);
  }
}
