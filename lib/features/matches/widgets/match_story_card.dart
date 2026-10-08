import 'package:flutter/material.dart';

import '../../../core/share/story_frame.dart';
import '../../../core/theme/app_text.dart';
import '../cubit/match_center_cubit.dart';
import '../match_live.dart';
import 'match_format.dart';

/// «ورقة الماتش» للشير: الفريقين والنتيجة كبيرة + الهدافين لكل فريق (الاسم مرة وجنبه الكور).
class MatchStoryCard extends StatelessWidget {
  const MatchStoryCard({super.key, required this.state, this.refCode});
  final MatchCenterState state;
  final String? refCode;

  @override
  Widget build(BuildContext context) {
    final m = state.match;
    final goals = MatchLive.grouped(state.events.where((e) => e.type == 'goal' || e.type == 'ownGoal').toList());
    List<String> scorers(int i) => [
      for (final g in goals)
        if (m.teams.length > 1 && (g.type == 'ownGoal') != (state.teamOf(g.playerId) == m.teams[i]))
          '${state.name(g.playerId)}${g.type == 'ownGoal' ? ' (عكسي)' : ''} ${List.filled(g.minutes.length, '⚽').join()}',
    ];
    Widget side(int i) => Expanded(
      child: Column(
        children: [
          Text(
            m.teams.length > i ? m.teams[i] : '',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppText.h(16, color: Colors.white),
          ),
          const SizedBox(height: 10),
          for (final s in scorers(i))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                s,
                textAlign: TextAlign.center,
                style: AppText.body(12, color: Colors.white70),
              ),
            ),
        ],
      ),
    );
    return StoryFrame(
      kicker: '${arabicWeekday(m.dateTime)} ${m.dateTime.day}/${m.dateTime.month} · ورقة الماتش',
      refCode: refCode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${m.scoreA ?? 0}  -  ${m.scoreB ?? 0}',
            textDirection: TextDirection.ltr,
            style: AppText.h(64, color: const Color(0xFF52C487), height: 1),
          ),
          Text(m.isFinished ? 'النتيجة النهائية' : '🔴 لايف', style: AppText.h(13, color: Colors.white)),
          const SizedBox(height: 18),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [side(0), const SizedBox(width: 10), side(1)]),
        ],
      ),
    );
  }
}
