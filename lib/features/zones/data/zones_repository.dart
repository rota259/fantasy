import 'zone.dart';

/// عقد المناطق.
abstract interface class ZonesRepository {
  /// كل المناطق بترتيبها (بتتحمّل مرة وبتتحفظ).
  Future<List<Zone>> fetchAll();

  /// منطقة بالـ id (من نفس الكاش).
  Future<Zone?> byId(int? id);

  /// تغيير منطقتي (مرة كل ٣٠ يوم).
  Future<void> setMine(int zoneId);
}
