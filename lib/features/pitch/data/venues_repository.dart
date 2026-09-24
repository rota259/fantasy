import 'dart:typed_data';

import 'models/venue.dart';

/// عقد بيانات الملاعب.
abstract interface class VenuesRepository {
  /// كل الملاعب.
  Future<List<Venue>> fetchAll();

  /// الملاعب اللي اليوزر ده صاحبها.
  Future<List<Venue>> fetchOwned(String userId);

  /// (مدير) إضافة ملعب (id فاضي) أو تعديله.
  Future<void> save(Venue venue);

  /// (مدير) حذف ملعب.
  Future<void> deleteVenue(String id);

  /// (مدير) رفع صورة وبيرجّع رابطها.
  Future<String> uploadPhoto(Uint8List bytes, String extension);
}
