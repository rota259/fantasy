import 'package:equatable/equatable.dart';

/// توقّع يوزر لنتيجة ماتش التحدّي.
class Prediction extends Equatable {
  const Prediction({required this.matchId, required this.scoreA, required this.scoreB});

  final String matchId;
  final int scoreA;
  final int scoreB;

  /// البونص لو التوقّع صح بالظبط.
  static const bonus = 5;

  bool matches(int? a, int? b) => a == scoreA && b == scoreB;

  factory Prediction.fromMap(Map<String, dynamic> m) => Prediction(
    matchId: m['match_id'].toString(),
    scoreA: (m['score_a'] as num).toInt(),
    scoreB: (m['score_b'] as num).toInt(),
  );

  @override
  List<Object?> get props => [matchId, scoreA, scoreB];
}
