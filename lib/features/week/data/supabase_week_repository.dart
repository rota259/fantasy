import '../../../core/supabase/supabase_service.dart';
import 'models/week_player.dart';
import 'week_repository.dart';

/// تنفيذ WeekRepository فوق دالة player_week_points + جدول matches.
class SupabaseWeekRepository implements WeekRepository {
  @override
  Future<int> latestWeek() async {
    final row = await SupabaseService.table('matches')
        .select('week')
        .order('week', ascending: false)
        .limit(1)
        .maybeSingle();
    return (row?['week'] as int?) ?? 1;
  }

  @override
  Future<List<WeekPlayer>> topPlayers(int week) async {
    final rows = await SupabaseService.client
        .rpc('player_week_points', params: {'w': week}) as List;
    return rows
        .map((r) => WeekPlayer.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
