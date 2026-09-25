import 'models/player_rating.dart';

/// عقد تقييم الجمهور (مفتوح ٢٤ ساعة بعد الماتش — الأعلى = رجل المباراة +٣).
abstract interface class RatingsRepository {
  /// تقييمات كل لاعيبة الماتش.
  Future<List<PlayerRating>> summary(String matchId);

  /// تقييمي للاعب من ١ لـ ١٠ (بيستبدل القديم).
  Future<void> rate(String matchId, String playerId, String userId, int rating);
}
