import 'models/game_match.dart';

/// عقد بيانات الماتشات/الجولات.
abstract interface class MatchesRepository {
  /// كل الماتشات مرتّبة بالتاريخ.
  Future<List<GameMatch>> fetchAll();

  /// الماتشات القادمة (upcoming) بس.
  Future<List<GameMatch>> fetchUpcoming();

  /// (مدير) إنشاء ماتش جديد.
  Future<void> addMatch({
    required List<String> teams,
    required DateTime dateTime,
    required int week,
  });

  /// (مدير) حذف ماتش.
  Future<void> deleteMatch(String id);
}
