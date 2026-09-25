import 'package:equatable/equatable.dart';

/// بداية ساعة الحجز. DateTime بيظبط الساعة ≥24 لليوم اللي بعده لوحده (ومن غير مشاكل التوقيت الصيفي).
DateTime slotStart(DateTime day, int hour) => DateTime(day.year, day.month, day.day, hour);

/// 21 → "9:00م" ، 24 → "12:00ص"
String formatHour(int h) {
  final x = h % 24;
  final t = x == 0 ? 12 : (x > 12 ? x - 12 : x);
  return '$t:00${x < 12 ? 'ص' : 'م'}';
}

/// تاريخ للداتابيز: 2026-09-24
String dbDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// حجز ساعة في ملعب (جدول bookings).
class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.day,
    required this.hour,
    required this.status,
    this.note,
    this.venueName,
    this.userName,
    this.userPhone,
  });

  final String id;
  final String venueId;
  final String userId;
  final DateTime day; // التاريخ (من غير وقت)
  final int hour; // ساعة البداية (≥24 = بعد نص الليل)
  final String status; // pending | confirmed | rejected | cancelled
  final String? note;
  // بيانات إضافية للعرض (من joins)
  final String? venueName;
  final String? userName;
  final String? userPhone;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isActive => isPending || isConfirmed;

  /// وقت بداية الحجز الفعلي (بيراعي الساعات بعد نص الليل).
  DateTime get start => slotStart(day, hour);
  bool get isPast => start.isBefore(DateTime.now());

  String get statusLabel => switch (status) {
    'confirmed' => 'مؤكد ✅',
    'rejected' => 'مرفوض ❌',
    'cancelled' => 'ملغي',
    _ => 'معلّق ⏳',
  };

  factory Booking.fromMap(Map<String, dynamic> m) {
    final venue = m['venues'] as Map<String, dynamic>?;
    final user = m['profiles'] as Map<String, dynamic>?;
    final userName = (user?['name'] as String?)?.trim();
    return Booking(
      id: m['id'].toString(),
      venueId: m['venue_id'].toString(),
      userId: m['user_id']?.toString() ?? '', // فاضي = حجز حد تاني (مخفي)
      day: DateTime.parse(m['day'] as String),
      hour: (m['hour'] as num).toInt(),
      status: (m['status'] ?? 'pending') as String,
      note: m['note'] as String?,
      venueName: venue?['name'] as String?,
      userName: (userName == null || userName.isEmpty) ? null : userName,
      userPhone: user?['phone'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, venueId, userId, day, hour, status, note];
}
