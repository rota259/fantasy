import '../../players/data/models/player.dart';
import '../../week/data/week_window.dart';
import 'models/fan_stats.dart';
import 'models/player_claim.dart';

/// عقد توثيق اللاعيبة الحقيقيين.
abstract interface class ClaimsRepository {
  /// آخر طلب ليا (أي حالة).
  Future<PlayerClaim?> mine(String userId);

  /// اللاعب اللي أنا موثّق عليه (null لو مش لاعب).
  Future<Player?> linkedPlayer(String userId);

  /// "ده أنا" — طلب توثيق بيروح للمدير.
  Future<void> request(String playerId, String userId, String? note);

  /// أرقامي كلاعب في الجولة.
  Future<FanStats> fanStats(String playerId, WeekWindow window);

  /// (مدير) الطلبات المعلّقة بالأسماء والموبايل.
  Future<List<PlayerClaim>> pending();

  /// (مدير) موافقة/رفض.
  Future<void> review(String claimId, bool approve);

  /// (مدير) فك التوثيق.
  Future<void> unlink(String playerId);
}
