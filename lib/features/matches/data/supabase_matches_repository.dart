import '../../../core/supabase/supabase_service.dart';
import 'matches_repository.dart';
import 'models/game_match.dart';

/// تنفيذ MatchesRepository فوق جدول matches في Supabase.
class SupabaseMatchesRepository implements MatchesRepository {
  static const _table = 'matches';

  @override
  Future<List<GameMatch>> fetchAll() async {
    final rows =
        await SupabaseService.table(_table).select().order('date_time');
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<List<GameMatch>> fetchUpcoming() async {
    final rows = await SupabaseService.table(_table)
        .select()
        .eq('status', 'upcoming')
        .order('date_time');
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<void> addMatch({
    required List<String> teams,
    required DateTime dateTime,
    required int week,
  }) async {
    await SupabaseService.table(_table).insert({
      'teams': teams,
      'date_time': dateTime.toIso8601String(),
      'week': week,
      'status': 'upcoming',
    });
  }

  @override
  Future<int> deleteMatch(String id) async {
    final rows = await SupabaseService.table(_table).delete().eq('id', id).select('id');
    return rows.length;
  }
}
