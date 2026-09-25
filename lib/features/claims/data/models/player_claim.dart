import 'package:equatable/equatable.dart';

/// طلب توثيق: يوزر بيقول إنه اللاعب ده في الحقيقة.
class PlayerClaim extends Equatable {
  const PlayerClaim({
    required this.id,
    required this.playerId,
    required this.userId,
    this.status = 'pending',
    this.playerName = '',
    this.team = '',
    this.userName = '',
    this.phone,
    this.note,
  });

  final String id;
  final String playerId;
  final String userId;
  final String status; // pending | approved | rejected
  final String playerName;
  final String team;
  final String userName;
  final String? phone; // للمدير بس (يتأكد بمكالمة)
  final String? note;

  bool get isPending => status == 'pending';

  factory PlayerClaim.fromMap(Map<String, dynamic> m) => PlayerClaim(
    id: m['id'].toString(),
    playerId: m['player_id'].toString(),
    userId: m['user_id'].toString(),
    status: (m['status'] ?? 'pending') as String,
    playerName: (m['player_name'] ?? '') as String,
    team: (m['team'] ?? '') as String,
    userName: (m['user_name'] ?? '') as String,
    phone: m['phone'] as String?,
    note: m['note'] as String?,
  );

  @override
  List<Object?> get props => [id, playerId, userId, status, note];
}
