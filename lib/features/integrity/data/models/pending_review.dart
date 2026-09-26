import 'package:equatable/equatable.dart';

import '../../../matches/data/models/game_match.dart';

/// ماتش مستني تأكيدي كلاعب موثّق فيه (my_pending_reviews).
class PendingReview extends Equatable {
  const PendingReview({required this.match, required this.myTeam});

  final GameMatch match; // فيه النتيجة والعلامات
  final String myTeam;

  factory PendingReview.fromMap(Map<String, dynamic> map) => PendingReview(
    match: GameMatch.fromMap({...map, 'status': 'finished', 'review_status': 'pending'}),
    myTeam: (map['my_team'] ?? '') as String,
  );

  @override
  List<Object?> get props => [match, myTeam];
}
