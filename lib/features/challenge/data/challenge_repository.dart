import '../../matches/data/models/game_match.dart';
import 'models/prediction.dart';

/// عقد تحدّي الجولة: المدير يختار ماتش، واليوزرز يتوقّعوا النتيجة (+٥ للصح).
abstract interface class ChallengeRepository {
  /// ماتش التحدّي الحالي: أقرب واحد لسه ملعبش، ولو مفيش آخر واحد خلص.
  Future<GameMatch?> current();

  Future<Prediction?> mine(String matchId, String userId);

  Future<void> predict(String matchId, String userId, int scoreA, int scoreB);

  /// بعد الماتش: كام واحد توقّع وكام جابها صح.
  Future<({int total, int correct})> summary(String matchId);

  /// الماتشات اللي اليوزر توقّع نتيجتها صح (لتفاصيل البونص).
  Future<List<GameMatch>> wonMatches(String userId);

  /// (مدير) إعلان ماتش تحدّي + إشعار للكل.
  Future<void> setChallenge(String matchId);
}
