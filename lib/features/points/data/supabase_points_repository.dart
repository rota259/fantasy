import '../../../core/supabase/supabase_service.dart';
import 'player_round_points.dart';
import 'points_repository.dart';

/// تنفيذ PointsRepository فوق دالة round_player_points.
class SupabasePointsRepository implements PointsRepository {
  @override
  Future<Map<String, PlayerRoundPoints>> roundPlayerPoints(DateTime roundEnd, List<String> playerIds) async {
    if (playerIds.isEmpty) return const {};
    final rows =
        await SupabaseService.client.rpc(
              'round_player_points',
              params: {'p_round': roundEnd.toUtc().toIso8601String(), 'p_players': playerIds},
            )
            as List;
    return {for (final r in rows.cast<Map<String, dynamic>>()) r['player_id'].toString(): PlayerRoundPoints.fromMap(r)};
  }
}
