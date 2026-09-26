import '../../../core/supabase/supabase_service.dart';
import 'zone.dart';
import 'zones_repository.dart';

/// تنفيذ ZonesRepository فوق جدول zones (بيتقري من غير دخول عشان التسجيل) + set_my_zone.
class SupabaseZonesRepository implements ZonesRepository {
  Future<List<Zone>>? _cache;

  @override
  Future<List<Zone>> fetchAll() => _cache ??= _load();

  Future<List<Zone>> _load() async {
    try {
      final rows = await SupabaseService.table('zones').select('id, governorate, name').order('sort');
      return rows.map(Zone.fromMap).toList();
    } catch (_) {
      _cache = null; // المحاولة الجاية تحمّل تاني
      rethrow;
    }
  }

  @override
  Future<Zone?> byId(int? id) async {
    if (id == null) return null;
    for (final z in await fetchAll()) {
      if (z.id == id) return z;
    }
    return null;
  }

  @override
  Future<void> setMine(int zoneId) async {
    await SupabaseService.client.rpc('set_my_zone', params: {'p_zone': zoneId});
  }
}
