import '../../../core/supabase/supabase_service.dart';
import 'events_repository.dart';
import 'models/match_event.dart';

/// تنفيذ EventsRepository فوق جدول events في Supabase.
class SupabaseEventsRepository implements EventsRepository {
  static const _table = 'events';

  @override
  Future<List<MatchEvent>> fetchByMatch(String matchId) async {
    final rows = await SupabaseService.table(_table).select().eq('match_id', matchId);
    return rows.map(MatchEvent.fromMap).toList();
  }

  @override
  Future<List<MatchEvent>> fetchByMatches(List<String> matchIds) async {
    if (matchIds.isEmpty) return const [];
    final rows = await SupabaseService.table(_table).select().inFilter('match_id', matchIds);
    return rows.map(MatchEvent.fromMap).toList();
  }

  @override
  Future<List<MatchEvent>> fetchByPlayer(String playerId) async {
    final rows = await SupabaseService.table(_table).select().eq('player_id', playerId);
    return rows.map(MatchEvent.fromMap).toList();
  }

  @override
  Future<List<MatchEvent>> fetchForPlayers(List<String> playerIds) async {
    if (playerIds.isEmpty) return const [];
    final rows = await SupabaseService.table(_table).select().inFilter('player_id', playerIds).order('minute');
    return rows.map(MatchEvent.fromMap).toList();
  }

  @override
  Future<void> addEvent({required String matchId, required String playerId, required String type, int? minute}) async {
    await SupabaseService.table(
      _table,
    ).insert({'match_id': matchId, 'player_id': playerId, 'type': type, 'minute': minute});
  }

  @override
  Future<void> deleteEvent(String id) async {
    await SupabaseService.table(_table).delete().eq('id', id);
  }
}
