import 'models/booking.dart';

/// عقد الحجوزات.
abstract interface class BookingsRepository {
  /// الحجوزات الفعّالة (معلّقة/مؤكدة) لملعب من يوم لحد يوم.
  Future<List<Booking>> forVenue(String venueId, DateTime from, DateTime to);

  /// طلب حجز ساعة (بيبقى معلّق لحد ما صاحب الملعب يوافق).
  Future<void> request({
    required String venueId,
    required String userId,
    required DateTime day,
    required int hour,
    String? note,
  });

  /// حجوزاتي (الأحدث الأول).
  Future<List<Booking>> mine(String userId);

  /// طلبات الحجز على ملاعب صاحب معيّن. ownerId = null → كل الحجوزات (للمدير).
  Future<List<Booking>> forOwner(String? ownerId);

  /// تغيير الحالة: confirmed | rejected | cancelled.
  Future<void> setStatus(String bookingId, String status);
}

/// الميعاد اتحجز لسه من حد تاني.
class SlotTakenException implements Exception {
  const SlotTakenException();
}
