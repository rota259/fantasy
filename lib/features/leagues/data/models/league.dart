import 'package:equatable/equatable.dart';

/// دوري (جدول leagues). العضوية في جدول league_members. صاحبه = اللي عمله.
class League extends Equatable {
  const League({
    required this.id,
    required this.name,
    required this.type,
    required this.inviteCode,
    this.memberCount = 0,
    this.ownerId,
    this.ownerName,
  });

  final String id;
  final String name;
  final String type; // 'global' | 'public' | 'private' | 'h2h'
  final String inviteCode;
  final int memberCount;
  final String? ownerId;
  final String? ownerName; // للمدير

  /// الدوري العام: كل اليوزرز فيه أوتوماتيك، مالوش كود ومحدش يخرج منه.
  bool get isGlobal => type == 'global';

  String get typeLabel => switch (type) {
    'global' => 'العام · كل اليوزرز',
    'h2h' => 'H2H',
    'private' => 'خاص',
    _ => 'كلاسيك',
  };

  factory League.fromMap(Map<String, dynamic> map) => League(
    id: map['id'].toString(),
    name: (map['name'] ?? '') as String,
    type: (map['type'] ?? 'public') as String,
    inviteCode: (map['invite_code'] ?? '') as String, // العام مالوش كود
    memberCount: (map['member_count'] ?? map['members'] ?? 0) as int,
    ownerId: map['owner_id']?.toString(),
    ownerName: map['owner_name'] as String?,
  );

  League copyWith({int? memberCount}) => League(
    id: id,
    name: name,
    type: type,
    inviteCode: inviteCode,
    memberCount: memberCount ?? this.memberCount,
    ownerId: ownerId,
    ownerName: ownerName,
  );

  @override
  List<Object?> get props => [id, name, type, inviteCode, memberCount, ownerId, ownerName];
}
