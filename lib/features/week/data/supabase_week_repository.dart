import '../../../core/supabase/supabase_service.dart';
import '../../../core/zone/zone_scope.dart';
import 'models/totw_candidates.dart';
import 'models/week_player.dart';
import 'week_window.dart';
import 'week_repository.dart';

/// تنفيذ WeekRepository فوق player_points_between + جدول team_of_week + دوال الأدمن.
class SupabaseWeekRepository implements WeekRepository {
  @override
  Future<List<WeekPlayer>> pointsBetween(DateTime from, DateTime to, {bool allZones = false}) async {
    final rows =
        await SupabaseService.client.rpc(
              'player_points_between',
              params: {
                'p_from': from.toUtc().toIso8601String(),
                'p_to': to.toUtc().toIso8601String(),
                'p_zone': allZones ? null : ZoneScope.current,
              },
            )
            as List;
    return rows.map((r) => WeekPlayer.fromMap(r as Map<String, dynamic>)).toList();
  }

  static String _db(DateTime t) => t.toUtc().toIso8601String();

  @override
  Future<List<WeekPlayer>?> publishedTeam(WeekWindow window) async {
    final zone = ZoneScope.current;
    if (zone == null) return null;
    final rows = await SupabaseService.table(
      'team_of_week',
    ).select('players').eq('round_end', _db(window.cutoff)).eq('zone_id', zone).limit(1);
    if (rows.isEmpty) return null;
    return [for (final p in rows.first['players'] as List) WeekPlayer.fromMap(p as Map<String, dynamic>)];
  }

  @override
  Future<WeekWindow?> latestPublishedRound() async {
    final zone = ZoneScope.current;
    if (zone == null) return null;
    final rows = await SupabaseService.table(
      'team_of_week',
    ).select('round_end').eq('zone_id', zone).order('round_end', ascending: false).limit(1);
    if (rows.isEmpty) return null;
    return WeekWindow(DateTime.parse(rows.first['round_end'] as String).toLocal());
  }

  @override
  Future<List<TotwCandidates>> candidates(WeekWindow window) async {
    final rows =
        await SupabaseService.client.rpc('admin_totw_candidates', params: {'p_round': _db(window.cutoff)}) as List;
    return rows.map((r) => TotwCandidates.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> publish(WeekWindow window, int zoneId, List<String> playerIds) async {
    await SupabaseService.client.rpc(
      'publish_totw',
      params: {'p_round': _db(window.cutoff), 'p_zone': zoneId, 'p_players': playerIds},
    );
  }
}
