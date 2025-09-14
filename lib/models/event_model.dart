class EventModel {
  final String eventId;
  final String matchId;
  final String playerId;
  final String type; // goal, assist, cleanSheet, yellowCard, etc.
  final int points;

  EventModel({
    required this.eventId,
    required this.matchId,
    required this.playerId,
    required this.type,
    required this.points,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) => EventModel(
    eventId: map['eventId'],
    matchId: map['matchId'],
    playerId: map['playerId'],
    type: map['type'],
    points: map['points'],
  );

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'matchId': matchId,
    'playerId': playerId,
    'type': type,
    'points': points,
  };
}
