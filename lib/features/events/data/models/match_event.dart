import 'package:equatable/equatable.dart';

/// حدث داخل ماتش (جول، أسيست، كارت...) بيحسب نقاط (جدول events).
class MatchEvent extends Equatable {
  const MatchEvent({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.type,
    this.minute,
    this.otherPlayerId,
  });

  final String id;
  final String matchId;
  final String playerId;
  final String type; // goal / assist / save / yellowCard / redCard / sub ...
  final int? minute; // دقيقة الحدث (للبث الحي)
  final String? otherPlayerId; // التبديل: اللاعب اللي طلع (playerId = اللي نزل)

  factory MatchEvent.fromMap(Map<String, dynamic> map) => MatchEvent(
    id: map['id'].toString(),
    matchId: map['match_id'].toString(),
    playerId: map['player_id'].toString(),
    type: (map['type'] ?? '') as String,
    minute: map['minute'] as int?,
    otherPlayerId: map['other_player_id']?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'match_id': matchId,
    'player_id': playerId,
    'type': type,
    'minute': minute,
  };

  @override
  List<Object?> get props => [id, matchId, playerId, type, minute, otherPlayerId];
}
