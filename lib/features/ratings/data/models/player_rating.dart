import 'package:equatable/equatable.dart';

/// تقييم الجمهور للاعب في ماتش: المتوسط + عدد الأصوات + تقييمي.
class PlayerRating extends Equatable {
  const PlayerRating({required this.playerId, this.avg, this.votes = 0, this.mine});

  final String playerId;
  final double? avg;
  final int votes;
  final int? mine;

  factory PlayerRating.fromMap(Map<String, dynamic> m) => PlayerRating(
    playerId: m['player_id'].toString(),
    avg: (m['avg'] as num?)?.toDouble(),
    votes: (m['votes'] as num?)?.toInt() ?? 0,
    mine: (m['mine'] as num?)?.toInt(),
  );

  @override
  List<Object?> get props => [playerId, avg, votes, mine];
}
