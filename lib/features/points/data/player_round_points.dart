import 'package:equatable/equatable.dart';

/// سطر في تفصيل النقط: "جول ×٢ (+١٠)" أو "بونص هاتريك (+٦)".
typedef ScoreItem = ({String label, int count, int points});

/// نقط لاعب في جولة من السيرفر (round_player_points) — المباشر والمعتمد + التفصيل.
class PlayerRoundPoints extends Equatable {
  const PlayerRoundPoints({
    required this.playerId,
    this.points = 0,
    this.finalPoints = 0,
    this.played = false,
    this.playedFinal = false,
    this.items = const [],
  });

  final String playerId;
  final int points; // كل الماتشات غير الملغية
  final int finalPoints; // الماتشات المعتمدة بس
  final bool played; // ليه نقط/أحداث في الجولة (للكابتن)
  final bool playedFinal;
  final List<ScoreItem> items;

  factory PlayerRoundPoints.fromMap(Map<String, dynamic> m) => PlayerRoundPoints(
    playerId: m['player_id'].toString(),
    points: (m['points'] as num?)?.toInt() ?? 0,
    finalPoints: (m['final_points'] as num?)?.toInt() ?? 0,
    played: (m['played'] ?? false) as bool,
    playedFinal: (m['played_final'] ?? false) as bool,
    items: [
      for (final i in (m['items'] as List? ?? const []).cast<Map<String, dynamic>>())
        (label: (i['k'] ?? '') as String, count: (i['n'] as num).toInt(), points: (i['p'] as num).toInt()),
    ],
  );

  @override
  List<Object?> get props => [playerId, points, finalPoints, played, playedFinal, items];
}
