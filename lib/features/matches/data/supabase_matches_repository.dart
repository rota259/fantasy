import '../../../core/supabase/supabase_service.dart';
import 'matches_repository.dart';
import 'models/game_match.dart';

/// تنفيذ MatchesRepository فوق جدول matches في Supabase.
class SupabaseMatchesRepository implements MatchesRepository {
  static const _table = 'matches';

  @override
  Future<List<GameMatch>> fetchAll() async {
    final rows = await SupabaseService.table(_table).select().order('date_time');
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<List<GameMatch>> fetchUpcoming() async {
    final rows = await SupabaseService.table(_table).select().eq('status', 'upcoming').order('date_time');
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<void> addMatch({required List<String> teams, required DateTime dateTime, required int week}) async {
    await SupabaseService.table(
      _table,
    ).insert({'teams': teams, 'date_time': GameMatch.dbTime(dateTime), 'week': week, 'status': 'upcoming'});
  }

  @override
  Future<List<GameMatch>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await SupabaseService.table(_table).select().inFilter('id', ids);
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<List<GameMatch>> fetchFinished() async {
    final rows = await SupabaseService.table(
      _table,
    ).select().eq('status', 'finished').order('date_time', ascending: false).limit(20);
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<void> finishMatch(String id, int scoreA, int scoreB) async {
    await SupabaseService.table(
      _table,
    ).update({'status': 'finished', 'score_a': scoreA, 'score_b': scoreB}).eq('id', id);
  }

  @override
  Future<void> updateMatch(
    String id, {
    required List<String> teams,
    required DateTime dateTime,
    required int week,
  }) async {
    await SupabaseService.table(
      _table,
    ).update({'teams': teams, 'date_time': GameMatch.dbTime(dateTime), 'week': week}).eq('id', id);
  }

  @override
  Future<int> deleteMatch(String id) async {
    final rows = await SupabaseService.table(_table).delete().eq('id', id).select('id');
    return rows.length;
  }
}
