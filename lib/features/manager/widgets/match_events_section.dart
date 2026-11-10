import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/box_field.dart';
import '../../../core/widgets/motion.dart';
import '../../events/data/models/match_event.dart';
import '../../matches/match_live.dart';
import '../../players/data/models/player.dart';
import '../../points/points_engine.dart';
import '../cubit/manager_match_cubit.dart';
import 'team_events_column.dart';

part 'match_events_section_parts.dart';

/// (مدير) تاب الأحداث: اختار الحدث، وبعدين دوس على اللاعب من نص فريقه.
/// كل نص فيه اللي في الملعب بس (الأساسيين + اللي نزلوا تبديل). الجول بيحدّث النتيجة لوحده.
class MatchEventsSection extends StatefulWidget {
  const MatchEventsSection({super.key, required this.cubit, required this.state});

  final ManagerMatchCubit cubit;
  final ManagerMatchState state;

  @override
  State<MatchEventsSection> createState() => _MatchEventsSectionState();
}

class _MatchEventsSectionState extends State<MatchEventsSection> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  String _type = 'goal';
  final _minute = TextEditingController();

  @override
  void dispose() {
    _minute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final cubit = widget.cubit;
    final teams = cubit.match.teams;
    if (s.lineup.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'نزّل تشكيلة الفريقين واحفظها الأول من تاب "التشكيلة" — بعدها اللي في الملعب هيظهروا هنا.',
          textAlign: TextAlign.center,
          style: AppText.body(13, color: AppColors.neutral700),
        ),
      );
    }
    final on = cubit.onPitch;
    final score = cubit.score;
    List<Player> pitchOf(String team) => [
      for (final p in s.players)
        if (p.team == team && on.contains(p.id)) p,
    ]..sort((a, b) => (a.position == 'GK' ? 0 : 1).compareTo(b.position == 'GK' ? 0 : 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('١. اختار الحدث', style: AppText.h(13)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final t in PointsEngine.managerEvents) _chip(t.$1, t.$2)]),
        const SizedBox(height: 10),
        BoxField(controller: _minute, hint: 'الدقيقة (اختياري)', keyboard: TextInputType.number),
        Text(_type == 'sub' ? '٢. دوس على اللاعب اللي هيطلع' : '٢. دوس على اللاعب', style: AppText.h(13)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TeamEventsColumn(
                team: teams.first,
                goals: score.a,
                players: pitchOf(teams.first),
                events: s.events,
                onTap: _record,
              ),
            ),
            Container(
              width: 1,
              height: 220,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Expanded(
              child: TeamEventsColumn(
                team: teams.last,
                goals: score.b,
                players: pitchOf(teams.last),
                events: s.events,
                onTap: _record,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('الأحداث المسجّلة', style: AppText.h(15)),
        const SizedBox(height: 6),
        if (s.events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('لسه مفيش أحداث', style: AppText.body(12, color: AppColors.neutral600)),
          ),
        for (final e in MatchLive.timeline(s.events).reversed) _eventRow(e),
      ],
    );
  }
}
