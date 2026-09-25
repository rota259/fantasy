import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import 'bookings_repository.dart';
import 'models/booking.dart';

/// تنفيذ BookingsRepository فوق جدول bookings + دوال السيرفر.
/// الحجز بيانات شخصية: المواعيد المشغولة بتيجي من venue_slots من غير أسماء،
/// والقوايم بالأسماء من booking_list (صاحب الملعب/المدير بس يشوفوا الموبايل).
/// الإشعارات (جوه التطبيق + push) بتتعمل من الداتابيز لوحدها.
class SupabaseBookingsRepository implements BookingsRepository {
  static const _table = 'bookings';

  @override
  Future<List<Booking>> forVenue(String venueId, DateTime from, DateTime to) async {
    final rows =
        await SupabaseService.client.rpc(
              'venue_slots',
              params: {'p_venue': venueId, 'p_from': dbDate(from), 'p_to': dbDate(to)},
            )
            as List;
    return rows.map((r) => Booking.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> request({
    required String venueId,
    required String userId,
    required DateTime day,
    required int hour,
    String? note,
  }) async {
    try {
      await SupabaseService.table(_table).insert({
        'venue_id': venueId,
        'user_id': userId,
        'day': dbDate(day),
        'hour': hour,
        'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const SlotTakenException(); // حد سبقه على نفس الميعاد
      rethrow;
    }
  }

  @override
  Future<List<Booking>> mine(String userId) => _list('mine');

  @override
  Future<List<Booking>> forOwner(String? ownerId) => _list(ownerId == null ? 'all' : 'owner');

  Future<List<Booking>> _list(String scope) async {
    final rows = await SupabaseService.client.rpc('booking_list', params: {'p_scope': scope}) as List;
    return rows.map((r) => Booking.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> setStatus(String bookingId, String status) async {
    await SupabaseService.client.rpc('set_booking_status', params: {'bid': bookingId, 'new_status': status});
  }
}
