import 'package:equatable/equatable.dart';

/// مكان الماتش: ملعب من الأبلكيشن ([venueId]) أو اسم + عنوان مكتوبين بالإيد.
class MatchPlace extends Equatable {
  const MatchPlace({required this.name, this.address, this.venueId});

  final String name;
  final String? address;
  final String? venueId;

  String get label => address == null ? name : '$name · $address';

  /// null لو الماتش مالوش مكان (ماتشات قديمة).
  static MatchPlace? fromMap(Map<String, dynamic> m) {
    final n = m['venue_name'] as String?;
    if (n == null || n.isEmpty) return null;
    return MatchPlace(name: n, address: m['venue_address'] as String?, venueId: m['venue_id']?.toString());
  }

  /// للكتابة: لو ملعب من الأبلكيشن السيرفر بيكمّل الاسم والعنوان منه.
  Map<String, dynamic> toWrite() => {'venue_id': venueId, 'venue_name': name, 'venue_address': address};

  @override
  List<Object?> get props => [name, address, venueId];
}
