import 'package:equatable/equatable.dart';

/// توقّع يوزر لنتيجة ماتش التحدّي (المهم فرق الأهداف).
class Prediction extends Equatable {
  const Prediction({required this.matchId, required this.scoreA, required this.scoreB});

  final String matchId;
  final int scoreA;
  final int scoreB;

  /// البونص لو فرق الأهداف صح.
  static const bonus = 5;

  /// صح = فرق الأهداف نفسه (مين كسب وبكام): توقّع ٣-١ والنتيجة ٢-٠ → صح.
  bool matches(int? a, int? b) => a != null && b != null && a - b == scoreA - scoreB;

  factory Prediction.fromMap(Map<String, dynamic> m) => Prediction(
    matchId: m['match_id'].toString(),
    scoreA: (m['score_a'] as num).toInt(),
    scoreB: (m['score_b'] as num).toInt(),
  );

  @override
  List<Object?> get props => [matchId, scoreA, scoreB];
}
