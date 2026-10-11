import '../../matches/data/models/game_match.dart';
import 'models/challenge_extras.dart';
import 'models/prediction.dart';

/// تحدّي كسبت منه: الماتش + النقط.
typedef ChallengeWin = ({GameMatch match, int points});

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

  /// التحدّيات اللي كسبت منها وكام نقطة (كل الأنواع + السلسلة) — المحسوب في السيرفر بس.
  Future<List<ChallengeWin>> wonMatches();

  /// الأنواع المختارة لكل تحدّي + لاعيبة الفريقين + إجاباتي + النتيجة ونقطي — وسلسلتي الحالية في فرق الأهداف.
  Future<({int streak, Map<String, ChallengeExtras> byMatch})> board();

  /// إجاباتي في «مين فيهم؟» · الـ٣ أسئلة · المعكوس (لحد قفل التوقّع).
  Future<void> answer(String matchId, ChallengeAnswers a);

  /// (مدير المنطقة من ماتشاته، أو الأدمن) إعلان ماتش تحدّي بالأنواع المختارة + إشعار لأهل المنطقة.
  /// [duelA] و[duelB]: لاعب من كل فريق لو «مين فيهم؟» مختار.
  Future<void> setChallenge(String matchId, {List<String> modes, String? duelA, String? duelB});
}
