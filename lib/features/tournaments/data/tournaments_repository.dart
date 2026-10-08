import '../../matches/data/models/game_match.dart';
import 'models/tournament.dart';

/// عقد البطولات.
abstract interface class TournamentsRepository {
  /// بطولات منطقة (الأحدث الأول).
  Future<List<Tournament>> list(int zoneId);

  Future<Tournament?> byId(String id);
  Future<List<TournamentTeam>> teams(String id);
  Future<List<GameMatch>> matches(String id);
  Future<List<TournamentRow>> standings(String id);
  Future<List<BracketSlot>> bracket(String id);
  Future<List<TournamentAward>> awards(String id);

  /// توقّعي للبطل (null = لسه) + كام واحد توقّع كل فريق.
  Future<(String?, Map<String, int>)> predictions(String id, String userId);

  /// (مدير/أدمن) بطولة جديدة — بيرجّع الـ id.
  Future<String> create({
    required String name,
    required String format,
    required int teamCount,
    required int groups,
    required DateTime startsAt,
    String? prize,
    String? sponsor,
    int? zoneId,
  });

  Future<void> addTeam(String id, String team);
  Future<void> requestTeam(String id, String team, String phone, String? note);
  Future<void> reviewTeam(String id, String team, bool approve);
  Future<void> draw(String id);
  Future<void> startKnockout(String id);
  Future<void> setWinner(String matchId, String team);
  Future<void> predict(String id, String team);
}
