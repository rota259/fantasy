import 'season.dart';

/// عقد السنين (كل سنة ميلادي = «موسم» بيتعمل أوتوماتيك في السيرفر — مفيش إضافة ولا تعديل من الأبلكيشن).
abstract interface class SeasonsRepository {
  /// كل السنين (الأحدث الأول).
  Future<List<Season>> fetchAll();
}
