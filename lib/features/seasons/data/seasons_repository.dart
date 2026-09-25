import 'season.dart';

/// عقد المواسم.
abstract interface class SeasonsRepository {
  /// كل المواسم (الأحدث الأول).
  Future<List<Season>> fetchAll();

  /// (مدير) إضافة موسم (id فاضي) أو تعديله.
  Future<void> save(Season season);

  /// (مدير) حذف موسم — بيمسح الكروت اللي اتستخدمت فيه.
  Future<void> delete(String id);
}
