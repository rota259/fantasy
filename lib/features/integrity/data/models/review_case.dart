import 'package:equatable/equatable.dart';

import '../../../matches/data/models/game_match.dart';

/// رأي لاعب في ورقة الماتش.
typedef ReviewVote = ({String name, String team, bool ok, String? note});

/// (أدمن) ماتش في طابور المراجعة: اعتراض أو علامات غرابة (admin_review_queue).
class ReviewCase extends Equatable {
  const ReviewCase({required this.match, required this.organizerName, required this.votes});

  final GameMatch match;
  final String organizerName;
  final List<ReviewVote> votes;

  bool get isDisputed => match.reviewStatus == 'disputed';

  factory ReviewCase.fromMap(Map<String, dynamic> map) => ReviewCase(
    match: GameMatch.fromMap({...map, 'status': 'finished'}),
    organizerName: (map['organizer_name'] ?? 'الأدمن') as String,
    votes: [
      for (final v in (map['reviews'] as List? ?? const []).cast<Map<String, dynamic>>())
        (
          name: (v['name'] ?? '') as String,
          team: (v['team'] ?? '') as String,
          ok: (v['ok'] ?? false) as bool,
          note: v['note'] as String?,
        ),
    ],
  );

  @override
  List<Object?> get props => [match, organizerName, votes];
}
