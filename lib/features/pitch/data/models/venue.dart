import 'package:equatable/equatable.dart';

/// ملعب للحجز (جدول venues).
/// المواعيد بالساعة: openHour..closeHour (closeHour ممكن > 24 = بعد نص الليل).
class Venue extends Equatable {
  const Venue({
    required this.id,
    required this.name,
    required this.price,
    this.surface = 'نجيلة صناعية',
    this.feature,
    this.lat,
    this.lng,
    this.phone,
    this.address,
    this.openHour = 16,
    this.closeHour = 24,
    this.photos = const [],
    this.ownerId,
    this.mapsUrl,
  });

  final String id;
  final String name;
  final int price; // جنيه/ساعة
  final String surface;
  final String? feature; // إضاءة / مغطّى ...
  final double? lat;
  final double? lng;
  final String? phone;
  final String? address;
  final int openHour;
  final int closeHour;
  final List<String> photos; // روابط الصور
  final String? ownerId; // صاحب الملعب (بيأكّد الحجوزات)
  final String? mapsUrl; // لينك جوجل مابس (الأدق)

  /// عنده إحداثيات (بيظهر كدبوس على خريطة التطبيق).
  bool get hasLocation => lat != null && lng != null;

  /// عنده أي موقع (لينك أو إحداثيات) — زرار "الموقع" يشتغل.
  bool get hasAnyLocation => hasLocation || (mapsUrl?.isNotEmpty ?? false);

  /// ساعات الحجز المتاحة في اليوم.
  List<int> get hours => [for (var h = openHour; h < closeHour; h++) h];

  factory Venue.fromMap(Map<String, dynamic> m) => Venue(
    id: m['id'].toString(),
    name: (m['name'] ?? '') as String,
    price: (m['price'] as num?)?.toInt() ?? 0,
    surface: (m['surface'] ?? 'نجيلة صناعية') as String,
    feature: m['feature'] as String?,
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    phone: m['phone'] as String?,
    address: m['address'] as String?,
    openHour: (m['open_hour'] as num?)?.toInt() ?? 16,
    closeHour: (m['close_hour'] as num?)?.toInt() ?? 24,
    photos: List<String>.from(m['photos'] ?? const []),
    ownerId: m['owner_id']?.toString(),
    mapsUrl: m['maps_url'] as String?,
  );

  /// الأعمدة القابلة للكتابة (للإضافة/التعديل).
  Map<String, dynamic> toWrite() => {
    'name': name,
    'price': price,
    'surface': surface,
    'feature': feature,
    'lat': lat,
    'lng': lng,
    'phone': phone,
    'address': address,
    'open_hour': openHour,
    'close_hour': closeHour,
    'photos': photos,
    'owner_id': ownerId,
    'maps_url': mapsUrl,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    surface,
    feature,
    lat,
    lng,
    phone,
    address,
    openHour,
    closeHour,
    photos,
    ownerId,
    mapsUrl,
  ];
}
