import 'package:equatable/equatable.dart';

/// منطقة: المحافظة + المنطقة (جدول zones).
class Zone extends Equatable {
  const Zone({required this.id, required this.governorate, required this.name});

  final int id;
  final String governorate;
  final String name;

  /// "بدر · القاهرة"
  String get label => '$name · $governorate';

  factory Zone.fromMap(Map<String, dynamic> m) => Zone(
    id: (m['id'] as num).toInt(),
    governorate: (m['governorate'] ?? '') as String,
    name: (m['name'] ?? '') as String,
  );

  @override
  List<Object?> get props => [id, governorate, name];
}
