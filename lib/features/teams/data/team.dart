import 'package:equatable/equatable.dart';

/// فريق: اسم مميّز + منطقة + صاحب (المدير) — جدول teams.
class Team extends Equatable {
  const Team({required this.id, required this.name, this.zoneId, this.ownerId, this.ownerName});

  final String id;
  final String name; // هو اللي في players.team و matches.teams
  final int? zoneId; // null = قديم/عام (الأدمن يحدده)
  final String? ownerId;
  final String? ownerName; // (للأدمن)

  factory Team.fromMap(Map<String, dynamic> m) => Team(
    id: m['id'].toString(),
    name: (m['name'] ?? '') as String,
    zoneId: (m['zone_id'] as num?)?.toInt(),
    ownerId: m['owner_id']?.toString(),
    ownerName: (m['owner'] as Map<String, dynamic>?)?['name'] as String?,
  );

  @override
  List<Object?> get props => [id, name, zoneId, ownerId, ownerName];
}
