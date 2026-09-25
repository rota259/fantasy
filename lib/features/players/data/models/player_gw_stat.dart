import 'package:equatable/equatable.dart';

/// إحصائيات لاعب في جولة: نقاطه + امتلاكه + حركة الدخول/الخروج.
class PlayerGwStat extends Equatable {
  const PlayerGwStat({
    required this.playerId,
    this.points = 0,
    this.owners = 0,
    this.ownership = 0,
    this.transfersIn = 0,
    this.transfersOut = 0,
    this.managers = 0,
  });

  final String playerId;
  final int points; // نقاطه في الجولة
  final int owners; // عدد اليوزرز اللي اختاروه
  final double ownership; // % الامتلاك
  final int transfersIn; // دخول (اختاروه جديد)
  final int transfersOut; // خروج (شالوه)
  final int managers; // عدد اليوزرز اللي عملوا تشكيلة في الجولة (مقام الامتلاك)

  static int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

  factory PlayerGwStat.fromMap(Map<String, dynamic> m) => PlayerGwStat(
    playerId: m['id'].toString(),
    points: _i(m['points']),
    owners: _i(m['owners']),
    ownership: (m['ownership'] as num?)?.toDouble() ?? 0,
    transfersIn: _i(m['transfers_in']),
    transfersOut: _i(m['transfers_out']),
    managers: _i(m['managers']),
  );

  @override
  List<Object?> get props => [playerId, points, owners, ownership, transfersIn, transfersOut, managers];
}
