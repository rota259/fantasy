import '../../../core/supabase/supabase_service.dart';
import '../../week/data/week_window.dart';
import 'models/player_gw_stat.dart';
import 'stats_repository.dart';

/// تنفيذ StatsRepository فوق جدول player_round_stats (محسوب مسبقًا كل ١٠ دقايق) + player_history.
class SupabaseStatsRepository implements StatsRepository {
  @override
  Future<Map<String, PlayerGwStat>> windowStats(WeekWindow week) async {
    final rows = await SupabaseService.table('player_round_stats')
        .select('id:player_id, points, owners, ownership, transfers_in, transfers_out, managers')
        .eq('round_end', week.cutoff.toUtc().toIso8601String());
    return {for (final r in rows) r['id'].toString(): PlayerGwStat.fromMap(r)};
  }

  @override
  Future<List<({int gw, int points})>> history(String playerId) async {
    final rows = await SupabaseService.client.rpc('player_history', params: {'p': playerId}) as List;
    return [for (final r in rows) (gw: (r['gw'] as num).toInt(), points: (r['points'] as num).toInt())];
  }
}
