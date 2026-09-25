import '../../../core/supabase/supabase_service.dart';
import 'season.dart';
import 'seasons_repository.dart';

/// تنفيذ SeasonsRepository فوق جدول seasons.
class SupabaseSeasonsRepository implements SeasonsRepository {
  static const _table = 'seasons';

  @override
  Future<List<Season>> fetchAll() async {
    final rows = await SupabaseService.table(_table).select().order('starts_at', ascending: false);
    return rows.map(Season.fromMap).toList();
  }

  @override
  Future<void> save(Season season) async {
    if (season.id.isEmpty) {
      await SupabaseService.table(_table).insert(season.toWrite());
    } else {
      await SupabaseService.table(_table).update(season.toWrite()).eq('id', season.id);
    }
  }

  @override
  Future<void> delete(String id) async {
    await SupabaseService.table(_table).delete().eq('id', id);
  }
}
