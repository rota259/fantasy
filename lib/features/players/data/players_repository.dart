import 'models/player.dart';

/// عقد بيانات اللاعيبة.
abstract interface class PlayersRepository {
  /// كل اللاعيبة المتاحين للاختيار.
  Future<List<Player>> fetchAll();

  /// اللاعيبة اللي الـ ids بتاعتهم موجودة في القائمة (تشكيلة مستخدم).
  Future<List<Player>> fetchByIds(List<String> ids);

  /// لاعيبة أندية معيّنة (لاختيار صاحب الحدث في الماتش).
  Future<List<Player>> fetchByTeams(List<String> teams);

  /// (مدير) إضافة لاعب جديد؛ بيرجّع id اللاعب.
  Future<String> addPlayer({
    required String name,
    required String team,
    required String position,
  });

  /// (مدير) حذف لاعب — بيرجّع عدد الصفوف المحذوفة (0 = مامعاكش صلاحية).
  Future<int> deletePlayer(String id);
}
