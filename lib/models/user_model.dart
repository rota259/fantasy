import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'user' أو 'manager'
  final String? fcmToken;
  final List<String> team;
  final String? leagueId;
  final String? photoUrl;
  final DateTime? createdAt;
  final bool isActive;
  final String? language;
  final String? favEuropeanTeam;
  final String? favLocalTeam;
  final String? position; // ← أضف دي هنا

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.fcmToken,
    required this.team,
    this.leagueId,
    this.photoUrl,
    this.createdAt,
    this.isActive = true,
    this.language,
    this.favEuropeanTeam,
    this.favLocalTeam,
    this.position, // ← أضف دي هنا
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'user',
      fcmToken: map['fcmToken'],
      team: List<String>.from(map['team'] ?? []),
      leagueId: map['leagueId'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
      language: map['language'],
      favEuropeanTeam: map['favEuropeanTeam'],
      favLocalTeam: map['favLocalTeam'],
          position: map['position'], // ← أضف دي هنا
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        if (fcmToken != null) 'fcmToken': fcmToken,
        'team': team,
        if (leagueId != null) 'leagueId': leagueId,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        'isActive': isActive,
        if (language != null) 'language': language,
        if (favEuropeanTeam != null) 'favEuropeanTeam': favEuropeanTeam,
        if (favLocalTeam != null) 'favLocalTeam': favLocalTeam,
            if (position != null) 'position': position, // ← أضف دي هنا
      };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? fcmToken,
    List<String>? team,
    String? leagueId,
    String? photoUrl,
    DateTime? createdAt,
    bool? isActive,
    String? language,
    String? favEuropeanTeam,
    String? favLocalTeam,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      team: team ?? this.team,
      leagueId: leagueId ?? this.leagueId,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      language: language ?? this.language,
      favEuropeanTeam: favEuropeanTeam ?? this.favEuropeanTeam,
      favLocalTeam: favLocalTeam ?? this.favLocalTeam,
      
    );
  }
}
