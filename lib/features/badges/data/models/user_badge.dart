import 'package:equatable/equatable.dart';

import '../badge_catalog.dart';

/// شارة عند يوزر: المستوى + التقدّم.
class UserBadge extends Equatable {
  const UserBadge({required this.key, required this.tier, required this.value, this.earnedAt});

  final String key;
  final int tier; // 0 لسه · 1 برونز · 2 فضة · 3 دهب
  final int value;
  final DateTime? earnedAt;

  BadgeDef? get def => BadgeCatalog.byKey(key);
  bool get earned => tier > 0;

  factory UserBadge.fromMap(Map<String, dynamic> m) => UserBadge(
    key: (m['badge'] ?? '') as String,
    tier: (m['tier'] as num?)?.toInt() ?? 0,
    value: (m['value'] as num?)?.toInt() ?? 0,
    earnedAt: m['earned_at'] == null ? null : DateTime.tryParse(m['earned_at'].toString())?.toLocal(),
  );

  @override
  List<Object?> get props => [key, tier, value, earnedAt];
}
