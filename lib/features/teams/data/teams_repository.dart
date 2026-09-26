import 'team.dart';

/// عقد الفرق.
abstract interface class TeamsRepository {
  /// فرقي كمنظّم.
  Future<List<Team>> mine(String userId);

  /// (أدمن) كل الفرق بأصحابها.
  Future<List<Team>> all();

  /// فريق جديد باسمي وفي منطقتي (السيرفر بيحددهم).
  Future<void> create(String name);

  /// حذف فريق (لو لسه ملوش لاعيبة ولا ماتشات).
  Future<void> delete(String id);

  /// (أدمن) تغيير منطقة فريق — لاعيبته وماتشاته الجاية بتتنقل معاه.
  Future<void> setZone(String id, int zoneId);
}
