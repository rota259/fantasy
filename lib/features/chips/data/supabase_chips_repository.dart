import '../../../core/supabase/supabase_service.dart';
import 'chip_type.dart';
import 'chips_repository.dart';
import 'models/chip_status.dart';

/// تنفيذ ChipsRepository فوق دوال chip_status / activate_chip وجدول chip_uses (week_cutoff = نهاية الجولة).
class SupabaseChipsRepository implements ChipsRepository {
  static String _db(DateTime t) => t.toUtc().toIso8601String();

  @override
  Future<List<ChipStatus>> status(DateTime roundEnd) async {
    final rows = await SupabaseService.client.rpc('chip_status', params: {'p_round': _db(roundEnd)}) as List;
    return [
      for (final r in rows)
        if (ChipStatus.fromMap(r as Map<String, dynamic>) case final s?) s,
    ];
  }

  @override
  Future<void> activate(DateTime roundEnd, ChipType type) async {
    await SupabaseService.client.rpc('activate_chip', params: {'p_round': _db(roundEnd), 'p_chip': type.key});
  }

  @override
  Future<Map<DateTime, ChipType>> usedByRound(String userId) async {
    final rows = await SupabaseService.table('chip_uses').select('week_cutoff, chip').eq('user_id', userId);
    return {
      for (final r in rows)
        if (ChipType.fromKey(r['chip'] as String?) case final t?)
          DateTime.parse(r['week_cutoff'].toString()).toLocal(): t,
    };
  }
}
