import '../../matches/data/models/game_match.dart';
import 'models/prediction.dart';

/// عقد تحدّي الجولة: كل مدير منطقة بيختار ماتش من ماتشاته، ويوزرز منطقته بس يتوقّعوا —
/// اللي يجيب فرق الأهداف صح ياخد +٥.
abstract interface class ChallengeRepository {
  /// تحدّيات منطقتي: اللي لسه ملعبتش + اللي خلصت في آخر أسبوع (الأقرب الأول).
  Future<List<GameMatch>> challenges();

  /// توقّعاتي في ماتشات معيّنة (بالـ match id).
  Future<Map<String, Prediction>> mine(List<String> matchIds, String userId);

  Future<void> predict(String matchId, String userId, int scoreA, int scoreB);

  /// بعد الماتش: كام واحد توقّع وكام جاب فرق الأهداف صح.
  Future<({int total, int correct})> summary(String matchId);

  /// الماتشات اللي اليوزر جاب فرق أهدافها صح (لتفاصيل البونص).
  Future<List<GameMatch>> wonMatches(String userId);

  /// (مدير المنطقة من ماتشاته، أو الأدمن) إعلان ماتش تحدّي + إشعار لأهل المنطقة.
  Future<void> setChallenge(String matchId);
}
