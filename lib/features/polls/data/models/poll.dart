import 'package:equatable/equatable.dart';

/// تصويت (نجم الجولة أو تحدّي الجولة) — المدير بيعمله.
class Poll extends Equatable {
  const Poll({required this.id, required this.kind, required this.question, this.active = true});

  final String id;
  final String kind; // star | challenge
  final String question;
  final bool active; // false = المدير قفله وأعلن الفايز

  factory Poll.fromMap(Map<String, dynamic> m) => Poll(
        id: m['id'].toString(),
        kind: (m['kind'] ?? 'challenge') as String,
        question: (m['question'] ?? '') as String,
        active: (m['active'] ?? true) as bool,
      );

  @override
  List<Object?> get props => [id, kind, question, active];
}

/// اختيار في التصويت + عدد أصواته وهل اليوزر مصوّت له.
class PollOption extends Equatable {
  const PollOption({
    required this.id,
    required this.label,
    this.playerId,
    this.votes = 0,
    this.mine = false,
  });

  final String id;
  final String label;
  final String? playerId;
  final int votes;
  final bool mine;

  PollOption copyWith({int? votes, bool? mine}) => PollOption(
        id: id,
        label: label,
        playerId: playerId,
        votes: votes ?? this.votes,
        mine: mine ?? this.mine,
      );

  factory PollOption.fromMap(Map<String, dynamic> m) => PollOption(
        id: m['id'].toString(),
        label: (m['label'] ?? '') as String,
        playerId: m['player_id']?.toString(),
      );

  @override
  List<Object?> get props => [id, label, playerId, votes, mine];
}

/// التصويت كامل بنتايجه.
class PollView extends Equatable {
  const PollView({required this.poll, required this.options});

  final Poll poll;
  final List<PollOption> options;

  int get totalVotes => options.fold(0, (s, o) => s + o.votes);
  bool get iVoted => options.any((o) => o.mine);

  /// الاختيار صاحب أكتر أصوات (null لو مفيش أصوات).
  PollOption? get winner {
    PollOption? best;
    for (final o in options) {
      if (o.votes > 0 && (best == null || o.votes > best.votes)) best = o;
    }
    return best;
  }

  @override
  List<Object?> get props => [poll, options];
}
