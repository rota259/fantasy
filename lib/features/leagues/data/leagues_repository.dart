import 'models/league_standing.dart';

/// عقد بيانات الدوريات والترتيب.
abstract interface class LeaguesRepository {
  /// الترتيب العام للمستخدم (حسب total_points).
  Future<int> globalRank(String userId);

  /// دوريات المستخدم مع ترتيبه في كل واحد.
  Future<List<MyLeague>> myLeagues(String userId);

  /// جدول ترتيب دوري معيّن (مرتّب بالنقاط).
  Future<List<LeagueStanding>> standings(String leagueId);

  /// الانضمام لدوري بكود الدعوة.
  Future<void> joinByCode(String inviteCode, String userId);
}
