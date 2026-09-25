import 'package:equatable/equatable.dart';

/// حالة لاعب في تشكيلة ماتش (جدول lineups).
class Lineup extends Equatable {
  const Lineup({required this.playerId, required this.status});

  final String playerId;
  final String status; // starting | bench

  factory Lineup.fromMap(Map<String, dynamic> map) =>
      Lineup(playerId: map['player_id'].toString(), status: (map['status'] ?? 'bench') as String);

  @override
  List<Object?> get props => [playerId, status];
}
