import 'package:equatable/equatable.dart';

/// لاعب في تشكيلة الأسبوع (نقاطه في الجولة).
class WeekPlayer extends Equatable {
  const WeekPlayer({
    required this.id,
    required this.name,
    required this.team,
    required this.position,
    required this.points,
  });

  final String id;
  final String name;
  final String team;
  final String position; // GK / DEF / MID / FWD
  final int points;

  String get positionAr => const {
        'GK': 'حارس', 'DEF': 'دفاع', 'MID': 'وسط', 'FWD': 'مهاجم',
      }[position] ??
      position;

  String get initials => name.trim().length >= 2 ? name.trim().substring(0, 2) : name;

  factory WeekPlayer.fromMap(Map<String, dynamic> map) => WeekPlayer(
        id: map['id'].toString(),
        name: (map['name'] ?? '') as String,
        team: (map['team'] ?? '') as String,
        position: (map['position'] ?? '') as String,
        points: (map['points'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, name, team, position, points];
}
