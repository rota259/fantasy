import 'package:fantasy_5omasi/features/pitch/data/maps_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('إحداثيات المكان (!3d!4d) أدق من وسط الشاشة (@)', () {
    const url = 'https://www.google.com/maps/place/X/@30.1,31.2,17z/data=!3m1!4b1!4m6!3m5!1s0x0:0x0!8m2!3d30.0561!4d31.3302';
    final p = MapsLink.parse(url)!;
    expect(p.latitude, 30.0561);
    expect(p.longitude, 31.3302);
  });

  test('لينك ?q= وبفاصلة متشفّرة', () {
    final p = MapsLink.parse('https://maps.google.com/?q=30.0444%2C31.2357')!;
    expect(p.latitude, 30.0444);
    expect(p.longitude, 31.2357);
  });

  test('لينك @ بس', () {
    final p = MapsLink.parse('https://www.google.com/maps/@29.9792,31.1342,15z')!;
    expect(p.latitude, 29.9792);
  });

  test('لينك مختصر مالوش إحداثيات من غير نت', () {
    expect(MapsLink.parse('https://maps.app.goo.gl/AbC123xyz'), isNull);
  });

  test('التعرّف على لينكات جوجل مابس', () {
    expect(MapsLink.isGoogleMaps('https://maps.app.goo.gl/AbC123'), isTrue);
    expect(MapsLink.isGoogleMaps('https://www.google.com/maps/place/x'), isTrue);
    expect(MapsLink.isGoogleMaps('https://maps.google.com/?q=1,2'), isTrue);
    expect(MapsLink.isGoogleMaps('https://goo.gl/maps/xyz'), isTrue);
    expect(MapsLink.isGoogleMaps('https://facebook.com/maps'), isFalse);
    expect(MapsLink.isGoogleMaps('مش لينك'), isFalse);
  });

  test('استخراج اللينك من نص المشاركة', () {
    expect(MapsLink.extractUrl('ملعب النصر\nhttps://maps.app.goo.gl/AbC123'), 'https://maps.app.goo.gl/AbC123');
  });
}
