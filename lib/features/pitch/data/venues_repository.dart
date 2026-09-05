import 'models/venue.dart';

/// عقد بيانات الملاعب.
abstract interface class VenuesRepository {
  /// كل الملاعب مرتّبة بالمسافة.
  Future<List<Venue>> fetchAll();
}
