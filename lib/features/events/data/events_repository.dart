import 'models/match_event.dart';

/// عقد بيانات أحداث الماتشات (النقاط).
abstract interface class EventsRepository {
  /// كل أحداث ماتش معيّن.
  Future<List<MatchEvent>> fetchByMatch(String matchId);

  /// كل أحداث لاعب معيّن (لحساب نقاطه).
  Future<List<MatchEvent>> fetchByPlayer(String playerId);

  /// أحداث مجموعة لاعيبة (تشكيلة المستخدم).
  Future<List<MatchEvent>> fetchForPlayers(List<String> playerIds);

  /// (مدير) إضافة حدث لماتش.
  Future<void> addEvent({
    required String matchId,
    required String playerId,
    required String type,
    int? minute,
  });

  /// (مدير) حذف حدث.
  Future<void> deleteEvent(String id);
}
