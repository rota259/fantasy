import '../../../core/supabase/supabase_service.dart';
import 'chip_type.dart';
import 'chips_repository.dart';
import 'models/chip_status.dart';

/// تنفيذ ChipsRepository فوق دوال chip_status / activate_chip وجدول chip_uses.
class SupabaseChipsRepository implements ChipsRepository {
  @override
  Future<List<ChipStatus>> status(String matchId) async {
    final rows = await SupabaseService.client.rpc('chip_status', params: {'p_match': matchId}) as List;
    return [
      for (final r in rows)
        if (ChipStatus.fromMap(r as Map<String, dynamic>) case final s?) s,
    ];
  }

  @override
  Future<void> activate(String matchId, ChipType type) async {
    await SupabaseService.client.rpc('activate_chip', params: {'p_match': matchId, 'p_chip': type.key});
  }

  @override
  Future<Map<String, ChipType>> usedByMatch(String userId) async {
    final rows = await SupabaseService.table('chip_uses').select('match_id, chip').eq('user_id', userId);
    return {
      for (final r in rows)
        if (ChipType.fromKey(r['chip'] as String?) case final t?) r['match_id'].toString(): t,
    };
  }
}
