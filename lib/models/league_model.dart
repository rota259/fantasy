class LeagueModel {
  final String leagueId;
  final String name;
  final String type; // "public" أو "private"
  final String inviteCode;
  final List<String> members;

  LeagueModel({
    required this.leagueId,
    required this.name,
    required this.type,
    required this.inviteCode,
    required this.members,
  });

  factory LeagueModel.fromMap(Map<String, dynamic> map) => LeagueModel(
    leagueId: map['leagueId'],
    name: map['name'],
    type: map['type'],
    inviteCode: map['inviteCode'],
    members: List<String>.from(map['members']),
  );

  Map<String, dynamic> toMap() => {
    'leagueId': leagueId,
    'name': name,
    'type': type,
    'inviteCode': inviteCode,
    'members': members,
  };
}
