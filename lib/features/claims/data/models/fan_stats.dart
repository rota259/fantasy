import 'package:equatable/equatable.dart';

/// أرقام "أنا كلاعب" في الجولة.
class FanStats extends Equatable {
  const FanStats({
    this.owners = 0,
    this.captains = 0,
    this.managers = 0,
    this.ownership = 0,
    this.posRank = 0,
    this.posTotal = 0,
    this.pointsForUsers = 0,
  });

  final int owners; // كام واحد اختارك
  final int captains; // كام واحد خلّاك كابتن
  final int managers; // كل اللي عملوا تشكيلة في الجولة
  final double ownership; // %
  final int posRank; // ترتيبك في مركزك بالامتلاك
  final int posTotal;
  final int pointsForUsers; // النقط اللي جبتها لليوزرز من أول الموسم

  static int _i(Object? v) => (v as num?)?.toInt() ?? 0;

  factory FanStats.fromMap(Map<String, dynamic> m) => FanStats(
    owners: _i(m['owners']),
    captains: _i(m['captains']),
    managers: _i(m['managers']),
    ownership: (m['ownership'] as num?)?.toDouble() ?? 0,
    posRank: _i(m['pos_rank']),
    posTotal: _i(m['pos_total']),
    pointsForUsers: _i(m['points_for_users']),
  );

  @override
  List<Object?> get props => [owners, captains, managers, ownership, posRank, posTotal, pointsForUsers];
}
