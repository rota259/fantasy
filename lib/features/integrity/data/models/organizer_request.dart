import 'package:equatable/equatable.dart';

/// طلب "عايز أنظّم ماتشات" (organizer_requests).
class OrganizerRequest extends Equatable {
  const OrganizerRequest({
    required this.id,
    required this.userId,
    this.status = 'pending',
    this.note,
    this.userName = '',
    this.phone,
    this.playerName,
  });

  final String id;
  final String userId;
  final String status; // pending · approved · rejected
  final String? note;
  final String userName; // (للأدمن)
  final String? phone; // (للأدمن)
  final String? playerName; // لو اليوزر لاعب موثّق

  bool get isPending => status == 'pending';

  factory OrganizerRequest.fromMap(Map<String, dynamic> map) => OrganizerRequest(
    id: map['id'].toString(),
    userId: map['user_id'].toString(),
    status: (map['status'] ?? 'pending') as String,
    note: map['note'] as String?,
    userName: (map['user_name'] ?? '') as String,
    phone: map['phone'] as String?,
    playerName: map['player_name'] as String?,
  );

  @override
  List<Object?> get props => [id, userId, status, note, userName, phone, playerName];
}
