import 'package:equatable/equatable.dart';

/// بيانات المستخدم (جدول profiles في Supabase، مرتبط بـ auth.users بالـ id).
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'user',
    this.team = const [],
    this.leagueId,
    this.photoUrl,
    this.position,
    this.captainId,
    this.totalPoints = 0,
    this.isActive = true,
    this.createdAt,
    this.refCode,
    this.zoneId,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'user' · 'organizer' (منظّم ماتشات) · 'manager' (الأدمن)
  final List<String> team; // ids اللاعيبة في التشكيلة
  final String? leagueId;
  final String? photoUrl;
  final String? position;
  final String? captainId; // id كابتن التشكيلة
  final int totalPoints; // نقاط اللاعب الإجمالية
  final bool isActive;
  final DateTime? createdAt;
  final String? refCode; // كود الدعوة بتاعه (بيظهر ليه بس)
  final int? zoneId; // منطقته (الماتشات والنجوم والتشكيلات بتاعتها)

  bool get isManager => role == 'manager';
  bool get isOrganizer => role == 'organizer';

  /// يقدر يعمل ماتشات ويدخّل أحداثها (المنظّم في ماتشاته، والأدمن في الكل).
  bool get canOrganize => isOrganizer || isManager;

  /// أول حرفين من الاسم (بديل الصورة).
  String get initials => name.trim().length >= 2 ? name.trim().substring(0, 2) : name;

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as String,
    name: (map['name'] ?? '') as String,
    email: (map['email'] ?? '') as String,
    phone: map['phone'] as String?,
    role: (map['role'] ?? 'user') as String,
    team: List<String>.from(map['team'] ?? const []),
    leagueId: map['league_id'] as String?,
    photoUrl: map['photo_url'] as String?,
    position: map['position'] as String?,
    captainId: map['captain_id'] as String?,
    totalPoints: (map['total_points'] ?? 0) as int,
    isActive: (map['is_active'] ?? true) as bool,
    createdAt: map['created_at'] == null ? null : DateTime.parse(map['created_at'] as String),
    refCode: map['ref_code'] as String?,
    zoneId: (map['zone_id'] as num?)?.toInt(),
  );

  /// الأعمدة اللي بتتكتب عند التسجيل (الدور والنقط بيحددهم السيرفر).
  Map<String, dynamic> toInsert() => {'id': id, 'name': name, 'email': email, 'phone': phone, 'zone_id': zoneId};

  AppUser copyWith({
    String? name,
    String? phone,
    String? role,
    List<String>? team,
    String? leagueId,
    String? photoUrl,
    String? position,
    String? captainId,
    int? totalPoints,
    bool? isActive,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    team: team ?? this.team,
    leagueId: leagueId ?? this.leagueId,
    photoUrl: photoUrl ?? this.photoUrl,
    position: position ?? this.position,
    captainId: captainId ?? this.captainId,
    totalPoints: totalPoints ?? this.totalPoints,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    refCode: refCode,
    zoneId: zoneId,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    role,
    team,
    leagueId,
    photoUrl,
    position,
    captainId,
    totalPoints,
    isActive,
    refCode,
    zoneId,
  ];
}
