/// منطقة في دوري المناطق: مجموع نقط ناسها.
class ZoneStanding {
  const ZoneStanding({
    required this.rank,
    required this.zoneId,
    required this.label,
    required this.users,
    required this.total,
    required this.avg,
    required this.mine,
  });

  final int rank;
  final int zoneId;
  final String label;
  final int users;
  final int total;
  final double avg;
  final bool mine; // منطقتي

  factory ZoneStanding.fromMap(Map<String, dynamic> m) => ZoneStanding(
    rank: (m['rank'] as num).toInt(),
    zoneId: (m['zone_id'] as num).toInt(),
    label: (m['label'] ?? '') as String,
    users: (m['users'] as num?)?.toInt() ?? 0,
    total: (m['total'] as num?)?.toInt() ?? 0,
    avg: (m['avg_points'] as num?)?.toDouble() ?? 0,
    mine: (m['mine'] ?? false) as bool,
  );
}
