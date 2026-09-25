import 'dart:typed_data';

import 'models/venue.dart';

/// عقد بيانات الملاعب.
abstract interface class VenuesRepository {
  /// كل الملاعب.
  Future<List<Venue>> fetchAll();

  /// الملاعب اللي اليوزر ده صاحبها.
  Future<List<Venue>> fetchOwned(String userId);

  /// إضافة ملعب (id فاضي) أو تعديله — صاحبه أو المدير.
  Future<void> save(Venue venue);

  /// حذف ملعب — صاحبه أو المدير.
  Future<void> deleteVenue(String id);

  /// رفع صورة في فولدر اليوزر وبيرجّع رابطها.
  Future<String> uploadPhoto(String userId, Uint8List bytes, String extension);

  /// متوسط تقييم كل ملعب: venueId → (المتوسط، العدد).
  Future<Map<String, ({double avg, int count})>> ratings();
}
