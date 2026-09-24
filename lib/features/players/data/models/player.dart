import 'package:equatable/equatable.dart';

/// لاعب في الدوري (جدول players).
class Player extends Equatable {
  const Player({
    required this.id,
    required this.name,
    required this.team,
    required this.position,
    required this.price,
    this.imageUrl,
    this.totalPoints = 0,
    this.form = 0,
    this.goals = 0,
    this.assists = 0,
    this.cleanSheets = 0,
    this.yellowCards = 0,
    this.availability = 'ready',
    this.news,
  });

  final String id;
  final String name;
  final String team;
  final String position; // GK / DEF / MID / FWD
  final double price;
  final String? imageUrl;
  final int totalPoints; // إجمالي النقاط
  final double form; // الفورمة (0..10)
  final int goals;
  final int assists;
  final int cleanSheets;
  final int yellowCards;
  final String availability; // ready | injured | doubtful | suspended
  final String? news; // سبب الحالة

  /// المركز بالعربي للعرض.
  String get positionAr => const {
        'GK': 'حارس',
        'DEF': 'دفاع',
        'MID': 'وسط',
        'FWD': 'مهاجم',
      }[position] ??
      position;

  /// أول حرفين من الاسم (بديل الصورة).
  String get initials => name.trim().length >= 2 ? name.trim().substring(0, 2) : name;

  factory Player.fromMap(Map<String, dynamic> map) => Player(
        id: map['id'].toString(),
        name: (map['name'] ?? '') as String,
        team: (map['team'] ?? '') as String,
        position: (map['position'] ?? '') as String,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        imageUrl: map['image_url'] as String?,
        totalPoints: (map['total_points'] ?? 0) as int,
        form: (map['form'] as num?)?.toDouble() ?? 0,
        goals: (map['goals'] ?? 0) as int,
        assists: (map['assists'] ?? 0) as int,
        cleanSheets: (map['clean_sheets'] ?? 0) as int,
        yellowCards: (map['yellow_cards'] ?? 0) as int,
        availability: (map['availability'] ?? 'ready') as String,
        news: map['news'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'team': team,
        'position': position,
        'price': price,
        'image_url': imageUrl,
        'total_points': totalPoints,
        'form': form,
        'goals': goals,
        'assists': assists,
        'clean_sheets': cleanSheets,
        'yellow_cards': yellowCards,
      };

  @override
  List<Object?> get props => [id, name, team, position, price, totalPoints, form];
}
