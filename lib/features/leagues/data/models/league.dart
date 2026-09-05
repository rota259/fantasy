import 'package:equatable/equatable.dart';

/// دوري (جدول leagues). العضوية في جدول league_members.
class League extends Equatable {
  const League({
    required this.id,
    required this.name,
    required this.type,
    required this.inviteCode,
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String type; // 'public' | 'private' | 'h2h'
  final String inviteCode;
  final int memberCount;

  String get typeLabel => switch (type) {
        'h2h' => 'H2H',
        'private' => 'خاص',
        _ => 'كلاسيك',
      };

  factory League.fromMap(Map<String, dynamic> map) => League(
        id: map['id'].toString(),
        name: (map['name'] ?? '') as String,
        type: (map['type'] ?? 'public') as String,
        inviteCode: (map['invite_code'] ?? '') as String,
        memberCount: (map['member_count'] ?? 0) as int,
      );

  League copyWith({int? memberCount}) => League(
        id: id,
        name: name,
        type: type,
        inviteCode: inviteCode,
        memberCount: memberCount ?? this.memberCount,
      );

  @override
  List<Object?> get props => [id, name, type, inviteCode, memberCount];
}
