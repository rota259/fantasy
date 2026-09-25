import 'models/league.dart';
import 'models/league_standing.dart';

/// عقد بيانات الدوريات والترتيب.
abstract interface class LeaguesRepository {
  /// الترتيب العام للمستخدم (النقط، والتعادل: اللاعيبة قليلة الامتلاك).
  Future<int> globalRank(String userId);

  /// دوريات المستخدم مع ترتيبه في كل واحد.
  Future<List<MyLeague>> myLeagues(String userId);

  /// جدول ترتيب دوري معيّن (النقط، والتعادل: اللاعيبة قليلة الامتلاك). العام = كل اليوزرز.
  Future<List<LeagueStanding>> standings(String leagueId);

  /// الانضمام لدوري بكود الدعوة (بيرمي رسالة السيرفر لو الكود غلط).
  Future<void> joinByCode(String inviteCode);

  /// (مدير) كل الدوريات بأصحابها وعدد أعضائها.
  Future<List<League>> fetchAll();

  /// أي يوزر يعمل دوري (لحد ١٠) بكود دعوة أوتوماتيك وبيبقى عضو فيه.
  Future<League> createLeague(String name, String type, String ownerId);

  /// حذف دوري — صاحبه أو المدير.
  Future<void> deleteLeague(String id);

  /// (مدير) الدوري العام — فيه كل اليوزرز أوتوماتيك (واحد بس).
  Future<void> createGlobalLeague(String name);

  /// الخروج من دوري.
  Future<void> leave(String leagueId, String userId);
}
