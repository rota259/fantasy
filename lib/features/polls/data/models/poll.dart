import 'package:equatable/equatable.dart';

/// أنواع التصويتات.
abstract final class PollKind {
  PollKind._();
  static const goalWeek = 'goal_week'; // هدف الجولة
  static const saveWeek = 'save_week'; // تصدّي الجولة
  static const goalSeason = 'goal_season'; // هدف الموسم (من فايزين الجولات)
  static const saveSeason = 'save_season';
  static const totwTie = 'totw_tie'; // تعادل على آخر مكان في تشكيلة الجولة
}

/// تصويت — المدير بيعمله (أو السيرفر لوحده في حالة التعادل).
class Poll extends Equatable {
  const Poll({
    required this.id,
    required this.kind,
    required this.question,
    this.active = true,
    this.createdAt,
    this.closesAt,
    this.windowEnd,
    this.slots = 1,
  });

  final String id;
  final String kind;
  final String question;
  final bool active; // false = اتقفل واتعلن الفايز
  final DateTime? createdAt;
  final DateTime? closesAt; // بيتقفل لوحده في الميعاد ده
  final DateTime? windowEnd; // الجولة (للتعادل)
  final int slots; // كام فايز

  /// مفتوح للتصويت دلوقتي.
  bool get open => active && (closesAt == null || DateTime.now().isBefore(closesAt!));

  static DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory Poll.fromMap(Map<String, dynamic> m) => Poll(
    id: m['id'].toString(),
    kind: (m['kind'] ?? '') as String,
    question: (m['question'] ?? '') as String,
    active: (m['active'] ?? true) as bool,
    createdAt: _date(m['created_at']),
    closesAt: _date(m['closes_at']),
    windowEnd: _date(m['window_end']),
    slots: (m['slots'] as num?)?.toInt() ?? 1,
  );

  @override
  List<Object?> get props => [id, kind, question, active, createdAt, closesAt, windowEnd, slots];
}

/// اختيار في التصويت + عدد أصواته وهل اليوزر مصوّت له.
class PollOption extends Equatable {
  const PollOption({
    required this.id,
    required this.label,
    this.playerId,
    this.videoUrl,
    this.matchId,
    this.votes = 0,
    this.mine = false,
  });

  final String id;
  final String label;
  final String? playerId;
  final String? videoUrl; // لينك الفيديو (هدف/تصدّي)
  final String? matchId;
  final int votes;
  final bool mine;

  PollOption copyWith({int? votes, bool? mine}) => PollOption(
    id: id,
    label: label,
    playerId: playerId,
    videoUrl: videoUrl,
    matchId: matchId,
    votes: votes ?? this.votes,
    mine: mine ?? this.mine,
  );

  factory PollOption.fromMap(Map<String, dynamic> m) => PollOption(
    id: m['id'].toString(),
    label: (m['label'] ?? '') as String,
    playerId: m['player_id']?.toString(),
    videoUrl: m['video_url'] as String?,
    matchId: m['match_id']?.toString(),
  );

  @override
  List<Object?> get props => [id, label, playerId, videoUrl, matchId, votes, mine];
}

/// التصويت كامل بنتايجه.
class PollView extends Equatable {
  const PollView({required this.poll, required this.options});

  final Poll poll;
  final List<PollOption> options;

  int get totalVotes => options.fold(0, (s, o) => s + o.votes);
  bool get iVoted => options.any((o) => o.mine);

  /// الفايزين (أكتر أصوات) — بعدد الأماكن. التعادل: بترتيب الاختيارات.
  List<PollOption> get winners {
    final withVotes = options.where((o) => o.votes > 0).toList();
    final order = {for (var i = 0; i < options.length; i++) options[i].id: i};
    withVotes.sort((a, b) {
      final c = b.votes.compareTo(a.votes);
      return c != 0 ? c : order[a.id]!.compareTo(order[b.id]!);
    });
    return withVotes.take(poll.slots).toList();
  }

  /// الفايز الأول (null لو مفيش أصوات).
  PollOption? get winner => winners.isEmpty ? null : winners.first;

  @override
  List<Object?> get props => [poll, options];
}

/// اختيار جديد بيضيفه المدير (مرشّح هدف/تصدّي).
typedef NewPollOption = ({String label, String? playerId, String? videoUrl, String? matchId});
