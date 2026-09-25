import '../../../core/supabase/supabase_service.dart';
import 'models/week_player.dart';
import 'week_repository.dart';

/// تنفيذ WeekRepository فوق دالة player_points_between (الجولة بالوقت).
class SupabaseWeekRepository implements WeekRepository {
  @override
  Future<List<WeekPlayer>> pointsBetween(DateTime from, DateTime to) async {
    final rows =
        await SupabaseService.client.rpc(
              'player_points_between',
              params: {'p_from': from.toUtc().toIso8601String(), 'p_to': to.toUtc().toIso8601String()},
            )
            as List;
    return rows.map((r) => WeekPlayer.fromMap(r as Map<String, dynamic>)).toList();
  }
}
