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
  String _type = 'goal';
  final _minute = TextEditingController();

  @override
  void dispose() {
    _minute.dispose();
    super.dispose();
  }

  Future<void> _record(Player p) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = widget.cubit;
    String? other;
    var target = p;
    if (_type == 'sub') {
      final bench = [
        for (final id in cubit.benchLeft)
          if (cubit.player(id) case final q? when q.team == p.team) q,
      ];
      final incoming = await showSubSheet(context, p, bench);
      if (incoming == null) return;
      other = p.id; // اللي طلع
      target = incoming; // اللي نزل
    }
    final err = await cubit.addEvent(target.id, _type, int.tryParse(_minute.text), otherPlayerId: other);
    final label = _type == 'sub' ? '${target.name} مكان ${p.name}' : p.name;
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? '${PointsEngine.eventIcon(_type)} ${PointsEngine.eventLabel(_type)} — $label ✓'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
        duration: Duration(milliseconds: err == null ? 1400 : 4000),
      ),
    );
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

  Widget _chip(String value, String label) {
    final on = _type == value;
    return Pressable(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: on ? AppColors.accent : AppColors.card,
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
        ),
        child: Text(label, style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
      ),
    );
  }

  Widget _eventRow(MatchEvent e) {
    final cubit = widget.cubit;
    final who = e.type == 'sub'
        ? '${cubit.playerName(e.playerId)} ⬆ · ${cubit.playerName(e.otherPlayerId ?? '')} ⬇'
        : cubit.playerName(e.playerId);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: AppDecor.softDivider,
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(e.minute != null ? "${e.minute}'" : '—', style: AppText.h(12, color: AppColors.accent)),
          ),
          Text(PointsEngine.eventIcon(e.type)),
          const SizedBox(width: 6),
          Expanded(child: Text(who, style: AppText.h(13))),
          Text(PointsEngine.eventLabel(e.type), style: AppText.body(11, color: AppColors.neutral700)),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => cubit.removeEvent(e.id),
            child: Icon(Icons.close, size: 18, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
