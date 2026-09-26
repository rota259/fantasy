import 'package:fantasy_5omasi/features/pitch/data/models/booking.dart';
import 'package:fantasy_5omasi/features/pitch/data/models/venue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatHour بالعربي مع ص/م وبعد نص الليل', () {
    expect(formatHour(9), '9:00ص');
    expect(formatHour(12), '12:00م');
    expect(formatHour(21), '9:00م');
    expect(formatHour(24), '12:00ص'); // نص الليل
    expect(formatHour(26), '2:00ص'); // 2 الفجر
  });

  test('slotStart: الساعة ≥24 بتروح لليوم اللي بعده', () {
    final day = DateTime(2026, 9, 30);
    expect(slotStart(day, 21), DateTime(2026, 9, 30, 21));
    expect(slotStart(day, 25), DateTime(2026, 10, 1, 1)); // آخر الشهر كمان
  });

  test('dbDate بصيغة الداتابيز', () {
    expect(dbDate(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('ساعات الملعب من الفتح للقفل (من غير ساعة القفل)', () {
    const v = Venue(id: '1', name: 'x', price: 100, openHour: 22, closeHour: 26);
    expect(v.hours, [22, 23, 24, 25]);
  });

  test('Booking.fromMap بياخد اسم الملعب والموبايل (من غير إيميل — خصوصية)', () {
    final b = Booking.fromMap({
      'id': 'b1',
      'venue_id': 'v1',
      'user_id': 'u1',
      'day': '2026-10-01',
      'hour': 25,
      'status': 'pending',
      'venues': {'name': 'ملعب النصر'},
      'profiles': {'name': '  ', 'phone': '010'},
    });
    expect(b.venueName, 'ملعب النصر');
    expect(b.userName, isNull);
    expect(b.userPhone, '010');
    expect(b.isPending && b.isActive, isTrue);
    expect(b.start, DateTime(2026, 10, 2, 1));
  });

  test('ميعاد محجوز لحد تاني بيرجع من غير صاحبه', () {
    final b = Booking.fromMap({
      'id': 'b2',
      'venue_id': 'v1',
      'user_id': null,
      'day': '2026-10-01',
      'hour': 20,
      'status': 'confirmed',
    });
    expect(b.userId, isEmpty);
    expect(b.isConfirmed, isTrue);
  });
}
