import '../../../core/supabase/supabase_service.dart';
import '../../week/data/week_window.dart';
import 'models/player_gw_stat.dart';
import 'stats_repository.dart';

/// تنفيذ StatsRepository فوق دوال player_window_stats / player_history.
class SupabaseStatsRepository implements StatsRepository {
  @override
  Future<Map<String, PlayerGwStat>> windowStats(WeekWindow week) async {
    final rows =
        await SupabaseService.client.rpc(
              'player_window_stats',
              params: {'p_from': week.start.toUtc().toIso8601String(), 'p_to': week.cutoff.toUtc().toIso8601String()},
            )
            as List;
    return {for (final r in rows) r['id'].toString(): PlayerGwStat.fromMap(r as Map<String, dynamic>)};
  }

  @override
  Future<List<({int gw, int points})>> history(String playerId) async {
    final rows = await SupabaseService.client.rpc('player_history', params: {'p': playerId}) as List;
    return [for (final r in rows) (gw: (r['gw'] as num).toInt(), points: (r['points'] as num).toInt())];
  }
}
