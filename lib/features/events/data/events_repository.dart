import 'models/match_event.dart';

/// عقد بيانات أحداث الماتشات (النقاط).
abstract interface class EventsRepository {
  /// كل أحداث ماتش معيّن.
  Future<List<MatchEvent>> fetchByMatch(String matchId);

  /// أحداث مجموعة ماتشات (لتفاصيل نقاط اليوزر).
  Future<List<MatchEvent>> fetchByMatches(List<String> matchIds);

  /// كل أحداث لاعب معيّن (لحساب نقاطه).
  Future<List<MatchEvent>> fetchByPlayer(String playerId);

  /// أحداث مجموعة لاعيبة (تشكيلة المستخدم).
  Future<List<MatchEvent>> fetchForPlayers(List<String> playerIds);

  /// (مدير) إضافة حدث لماتش. التبديل: [playerId] اللي نزل و[otherPlayerId] اللي طلع.
  Future<void> addEvent({
    required String matchId,
    required String playerId,
    required String type,
    int? minute,
    String? otherPlayerId,
  });

  /// (مدير) حذف حدث.
  Future<void> deleteEvent(String id);
}
