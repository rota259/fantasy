import 'package:equatable/equatable.dart';

/// اختيار لاعب في تشكيلة المستخدم لماتش معيّن (جدول picks).
class Pick extends Equatable {
  const Pick({
    required this.playerId,
    required this.status,
    this.isCaptain = false,
    this.isVice = false,
  });

  final String playerId;
  final String status; // starting | bench
  final bool isCaptain;
  final bool isVice; // كابتن احتياطي

  factory Pick.fromMap(Map<String, dynamic> map) => Pick(
        playerId: map['player_id'].toString(),
        status: (map['status'] ?? 'starting') as String,
        isCaptain: (map['is_captain'] ?? false) as bool,
        isVice: (map['is_vice'] ?? false) as bool,
      );

  @override
  List<Object?> get props => [playerId, status, isCaptain, isVice];
}
