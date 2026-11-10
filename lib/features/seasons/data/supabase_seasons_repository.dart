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
}
