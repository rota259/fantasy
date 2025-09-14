class PlayerModel {
  final String playerId;
  final String name;
  final String team;
  final String position;
  final double price;
  final String imageUrl;
  final int goals;
  final int cleanSheets;
  final int yellowCards;

  PlayerModel({
    required this.playerId,
    required this.name,
    required this.team,
    required this.position,
    required this.price,
    required this.imageUrl,
    required this.goals,
    required this.cleanSheets,
    required this.yellowCards,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) => PlayerModel(
    playerId: map['playerId'],
    name: map['name'],
    team: map['team'],
    position: map['position'],
    price: (map['price'] as num).toDouble(),
    imageUrl: map['imageUrl'],
    goals: map['stats']['goals'] ?? 0,
    cleanSheets: map['stats']['cleanSheets'] ?? 0,
    yellowCards: map['stats']['yellowCards'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'playerId': playerId,
    'name': name,
    'team': team,
    'position': position,
    'price': price,
    'imageUrl': imageUrl,
    'stats': {
      'goals': goals,
      'cleanSheets': cleanSheets,
      'yellowCards': yellowCards,
    },
  };
}
