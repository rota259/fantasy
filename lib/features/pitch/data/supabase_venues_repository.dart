import '../../../core/supabase/supabase_service.dart';
import 'models/venue.dart';
import 'venues_repository.dart';

/// تنفيذ VenuesRepository فوق جدول venues.
class SupabaseVenuesRepository implements VenuesRepository {
  static const _table = 'venues';

  @override
  Future<List<Venue>> fetchAll() async {
    final rows = await SupabaseService.table(_table).select().order('distance_km');
    return rows.map(Venue.fromMap).toList();
  }
}
