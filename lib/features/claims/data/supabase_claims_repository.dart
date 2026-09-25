import '../../../core/supabase/supabase_service.dart';
import '../../players/data/models/player.dart';
import '../../week/data/week_window.dart';
import 'claims_repository.dart';
import 'models/fan_stats.dart';
import 'models/player_claim.dart';

/// تنفيذ ClaimsRepository فوق player_claims + دوال review_claim / pending_claims / player_fan_stats.
class SupabaseClaimsRepository implements ClaimsRepository {
  @override
  Future<PlayerClaim?> mine(String userId) async {
    final rows = await SupabaseService.table(
      'player_claims',
    ).select().eq('user_id', userId).order('created_at', ascending: false).limit(1);
    return rows.isEmpty ? null : PlayerClaim.fromMap(rows.first);
  }

  @override
  Future<Player?> linkedPlayer(String userId) async {
    final row = await SupabaseService.table('players').select().eq('user_id', userId).maybeSingle();
    return row == null ? null : Player.fromMap(row);
  }

  @override
  Future<void> request(String playerId, String userId, String? note) async {
    await SupabaseService.table('player_claims').insert({
      'player_id': playerId,
      'user_id': userId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  @override
  Future<FanStats> fanStats(String playerId, WeekWindow window) async {
    final rows =
        await SupabaseService.client.rpc(
              'player_fan_stats',
              params: {
                'p_player': playerId,
                'p_from': window.start.toUtc().toIso8601String(),
                'p_to': window.cutoff.toUtc().toIso8601String(),
              },
            )
            as List;
    return rows.isEmpty ? const FanStats() : FanStats.fromMap(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<PlayerClaim>> pending() async {
    final rows = await SupabaseService.client.rpc('pending_claims') as List;
    return rows.map((r) => PlayerClaim.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> review(String claimId, bool approve) async {
    await SupabaseService.client.rpc('review_claim', params: {'p_claim': claimId, 'p_approve': approve});
  }

  @override
  Future<void> unlink(String playerId) async {
    await SupabaseService.client.rpc('unlink_player', params: {'p_player': playerId});
  }
}
