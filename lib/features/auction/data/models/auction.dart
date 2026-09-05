import 'package:equatable/equatable.dart';

import '../../../players/data/models/player.dart';

/// غرفة مزاد (جدول auctions) مع اللاعب المعروض حاليًا.
class Auction extends Equatable {
  const Auction({
    required this.id,
    required this.name,
    required this.basePrice,
    this.endsAt,
    this.player,
  });

  final String id;
  final String name;
  final double basePrice;
  final DateTime? endsAt;
  final Player? player; // اللاعب المعروض حاليًا

  factory Auction.fromMap(Map<String, dynamic> map) => Auction(
        id: map['id'].toString(),
        name: (map['name'] ?? '') as String,
        basePrice: (map['base_price'] as num?)?.toDouble() ?? 0,
        endsAt: map['ends_at'] == null ? null : DateTime.parse(map['ends_at'] as String),
        player: map['players'] == null
            ? null
            : Player.fromMap(map['players'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [id, name, basePrice, endsAt, player];
}
