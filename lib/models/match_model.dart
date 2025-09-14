class MatchModel {
  final String matchId;
  final DateTime dateTime;
  final List<String> teams;
  final String status; // "upcoming" أو "finished"
  final int week;

  MatchModel({
    required this.matchId,
    required this.dateTime,
    required this.teams,
    required this.status,
    required this.week,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map) => MatchModel(
    matchId: map['matchId'],
    dateTime: DateTime.parse(map['dateTime']),
    teams: List<String>.from(map['teams']),
    status: map['status'],
    week: map['week'],
  );

  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'dateTime': dateTime.toIso8601String(),
    'teams': teams,
    'status': status,
    'week': week,
  };
}
