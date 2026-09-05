import 'package:equatable/equatable.dart';

/// حدث داخل ماتش (جول، أسيست، كارت...) بيحسب نقاط (جدول events).
class MatchEvent extends Equatable {
  const MatchEvent({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.type,
    this.minute,
  });

  final String id;
  final String matchId;
  final String playerId;
  final String type; // goal / assist / cleanSheet / yellowCard ...
  final int? minute; // دقيقة الحدث (للبث الحي)

  factory MatchEvent.fromMap(Map<String, dynamic> map) => MatchEvent(
        id: map['id'].toString(),
        matchId: map['match_id'].toString(),
        playerId: map['player_id'].toString(),
        type: (map['type'] ?? '') as String,
        minute: map['minute'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'match_id': matchId,
        'player_id': playerId,
        'type': type,
        'minute': minute,
      };

  @override
  List<Object?> get props => [id, matchId, playerId, type, minute];
}
