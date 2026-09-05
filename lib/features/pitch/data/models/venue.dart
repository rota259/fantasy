import 'package:equatable/equatable.dart';

/// ملعب للحجز (جدول venues).
class Venue extends Equatable {
  const Venue({
    required this.id,
    required this.name,
    required this.price,
    required this.distanceKm,
    required this.surface,
    this.feature,
    this.capacity = 10,
    this.filled = 0,
    this.slotTime = '',
  });

  final String id;
  final String name;
  final int price; // بالجنيه/الساعة
  final double distanceKm;
  final String surface; // نوع النجيلة
  final String? feature; // إضاءة / مغطّى ...
  final int capacity;
  final int filled;
  final String slotTime; // ميعاد متاح

  bool get isFull => filled >= capacity;
  double get fill => capacity == 0 ? 0 : (filled / capacity).clamp(0, 1);

  factory Venue.fromMap(Map<String, dynamic> map) => Venue(
        id: map['id'].toString(),
        name: (map['name'] ?? '') as String,
        price: (map['price'] ?? 0) as int,
        distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
        surface: (map['surface'] ?? '') as String,
        feature: map['feature'] as String?,
        capacity: (map['capacity'] ?? 10) as int,
        filled: (map['filled'] ?? 0) as int,
        slotTime: (map['slot_time'] ?? '') as String,
      );

  @override
  List<Object?> get props => [id, name, price, distanceKm, surface, capacity, filled];
}
