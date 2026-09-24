import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import 'bookings_repository.dart';
import 'models/booking.dart';

/// تنفيذ BookingsRepository فوق جدول bookings + دالة set_booking_status + push.
class SupabaseBookingsRepository implements BookingsRepository {
  static const _table = 'bookings';
  static const _withNames = '*, venues!inner(name, owner_id), profiles(name, email, phone)';

  @override
  Future<List<Booking>> forVenue(String venueId, DateTime from, DateTime to) async {
    final rows = await SupabaseService.table(_table)
        .select()
        .eq('venue_id', venueId)
        .inFilter('status', ['pending', 'confirmed'])
        .gte('day', dbDate(from))
        .lte('day', dbDate(to));
    return rows.map(Booking.fromMap).toList();
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
      final row = await SupabaseService.table(_table)
          .insert({
            'venue_id': venueId,
            'user_id': userId,
            'day': dbDate(day),
            'hour': hour,
            'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
          })
          .select('id')
          .single();
      _push(row['id'].toString());
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const SlotTakenException(); // حد سبقه على نفس الميعاد
      rethrow;
    }
  }

  @override
  Future<List<Booking>> mine(String userId) async {
    final rows = await SupabaseService.table(_table)
        .select(_withNames)
        .eq('user_id', userId)
        .order('day', ascending: false)
        .order('hour', ascending: false);
    return rows.map(Booking.fromMap).toList();
  }

  @override
  Future<List<Booking>> forOwner(String? ownerId) async {
    var q = SupabaseService.table(_table).select(_withNames);
    if (ownerId != null) q = q.eq('venues.owner_id', ownerId);
    final rows = await q.order('day', ascending: false).order('hour', ascending: false);
    return rows.map(Booking.fromMap).toList();
  }

  @override
  Future<void> setStatus(String bookingId, String status) async {
    await SupabaseService.client.rpc('set_booking_status', params: {'bid': bookingId, 'new_status': status});
    _push(bookingId);
  }

  /// push للطرف التاني في الحجز (الإشعار جوه التطبيق بيتعمل من الداتابيز أصلًا).
  void _push(String bookingId) {
    SupabaseService.client.functions
        .invoke('notify-match', body: {'booking_id': bookingId})
        .then((_) {}, onError: (_) {});
  }
}
