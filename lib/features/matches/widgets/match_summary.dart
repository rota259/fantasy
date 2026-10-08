import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../points/points_engine.dart';
import '../cubit/match_center_cubit.dart';
import '../match_live.dart';
import '../../../core/theme/app_spacing.dart';

/// ملخص الأحداث المهمة تحت النتيجة: كل فريق في ناحيته (أهداف · كروت · بلنتي · تبديل).
/// نفس اللاعب ونفس الحدث سطر واحد: «فلان ⚽⚽⚽ 12' 30' 44'» — والأحداث المختلفة كل واحد في سطر.
/// الجول العكسي بيظهر عند الفريق اللي استفاد منه.
class MatchSummary extends StatelessWidget {
  const MatchSummary({super.key, required this.state});
  final MatchCenterState state;

  @override
  Widget build(BuildContext context) {
    final teams = state.match.teams;
    final key = MatchLive.grouped(state.events.where((e) => PointsEngine.highlights.contains(e.type)).toList());
    if (key.isEmpty || teams.length < 2) return const SizedBox.shrink();
    List<EventGroup> side(int i) => [
      for (final g in key)
        if ((g.type == 'ownGoal') != (state.teamOf(g.playerId) == teams[i])) g,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _column(side(0), TextAlign.start)),
          const SizedBox(width: 12),
          Expanded(child: _column(side(1), TextAlign.end)),
        ],
      ),
    );
  }

  Widget _column(List<EventGroup> list, TextAlign align) => Column(
    crossAxisAlignment: align == TextAlign.start ? CrossAxisAlignment.start : CrossAxisAlignment.end,
    children: [
      for (final (i, g) in list.indexed)
        FadeSlideIn(
          index: i,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${_who(g)} ', style: AppText.h(12)),
                  TextSpan(text: _icons(g)),
                  if (_minutes(g).isNotEmpty)
                    TextSpan(
                      text: ' ${_minutes(g)}',
                      style: AppText.body(10, color: AppColors.neutral600),
                    ),
                ],
              ),
              textAlign: align,
              style: AppText.body(12),
            ),
          ),
        ),
    ],
  );

  /// الأيقونة بعدد المرات (ولو كتير: أيقونة ×العدد).
  static String _icons(EventGroup g) {
    final icon = PointsEngine.eventIcon(g.type);
    final n = g.minutes.length;
    return n <= 4 ? List.filled(n, icon).join() : '$icon ×$n';
  }

  static String _minutes(EventGroup g) => [
    for (final m in g.minutes)
      if (m != null) "$m'",
  ].join(' ');

  String _who(EventGroup g) => switch (g.type) {
    'sub' => '${state.name(g.playerId)} ⬆ ${state.name(g.otherPlayerId)} ⬇',
    'ownGoal' => '${state.name(g.playerId)} (عكسي)',
    'penaltyMiss' => '${state.name(g.playerId)} (ضيّع بلنتي)',
    'penaltySave' => '${state.name(g.playerId)} (صد بلنتي)',
    'insult' => '${state.name(g.playerId)} (سب)',
    _ => state.name(g.playerId),
  };
}

/// كل الأحداث بالترتيب (الأحدث فوق) — حتى التصديات والتدخلات.
class MatchTimeline extends StatelessWidget {
  const MatchTimeline({super.key, required this.state});
  final MatchCenterState state;

  @override
  Widget build(BuildContext context) {
    final list = MatchLive.timeline(state.events).reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Text('كل الأحداث', style: AppText.h(15)),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('لسه مفيش أحداث', style: AppText.body(12, color: AppColors.neutral600)),
          ),
        for (final e in list)
          Container(
            margin: AppDecor.tileMargin,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: AppDecor.tile,
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(e.minute != null ? "${e.minute}'" : '—', style: AppText.h(12, color: AppColors.accent)),
                ),
                Text(PointsEngine.eventIcon(e.type)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.type == 'sub'
                        ? '${state.name(e.playerId)} مكان ${state.name(e.otherPlayerId)}'
                        : state.name(e.playerId),
                    style: AppText.h(13),
                  ),
                ),
                Text(
                  '${PointsEngine.eventLabel(e.type)} · ${state.teamOf(e.playerId) ?? ''}',
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
