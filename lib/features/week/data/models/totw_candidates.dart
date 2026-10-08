import 'package:equatable/equatable.dart';

import '../team_of_week.dart';

import 'week_player.dart';

/// (أدمن) اقتراح تشكيلة الجولة لمنطقة (admin_totw_candidates).
class TotwCandidates extends Equatable {
  const TotwCandidates({
    required this.zoneId,
    required this.zoneLabel,
    required this.candidates,
    this.slots = 0,
    this.tieOpen = false,
    this.tieWinners = const [],
    this.published = false,
  });

  final int zoneId; // 0 = الماتشات العامة
  final String zoneLabel;
  final List<WeekPlayer> candidates; // أعلى ١٢ نقط
  final int slots; // أماكن عليها تصويت تعادل
  final bool tieOpen; // اليوزرز لسه بيصوّتوا
  final List<String> tieWinners; // فايزين التصويت (بعد ما يخلص)
  final bool published;

  /// الاقتراح الافتراضي: أعلى حارس + أعلى ٤ (غير الحراس)، ولو فيه تعادل على آخر مكان → فايزين التصويت.
  List<String> get suggested {
    final team = TeamOfWeek.build(candidates);
    return [
      for (final p in team.lineup(winnerIds: tieWinners))
        if (p != null) p.id,
    ];
  }

  factory TotwCandidates.fromMap(Map<String, dynamic> m) => TotwCandidates(
    zoneId: (m['zone_id'] as num).toInt(),
    zoneLabel: (m['zone_label'] ?? '') as String,
    candidates: [for (final c in (m['candidates'] as List? ?? const [])) WeekPlayer.fromMap(c as Map<String, dynamic>)],
    slots: (m['slots'] as num?)?.toInt() ?? 0,
    tieOpen: (m['tie_open'] ?? false) as bool,
    tieWinners: [for (final w in (m['tie_winners'] as List? ?? const [])) w.toString()],
    published: (m['published'] ?? false) as bool,
  );

  @override
  List<Object?> get props => [zoneId, zoneLabel, candidates, slots, tieOpen, tieWinners, published];
}
