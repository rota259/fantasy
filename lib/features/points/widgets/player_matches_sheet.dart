import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/widgets/match_format.dart';
import '../../week/data/week_window.dart';
import '../data/player_match_line.dart';
import '../data/points_repository.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// شيت "عمل إيه في الجولة" (نجم الجولة / لاعب في تشكيلة الجولة):
/// كل ماتش لعبه — ضد مين · النتيجة · نقطه · التفصيل (أهداف · أسيست · تصديات …).
Future<void> showPlayerMatchesSheet(
  BuildContext context, {
  required String playerId,
  required String name,
  required String team,
  required WeekWindow window,
  String? subtitle,
}) {
  final future = context.read<PointsRepository>().playerRoundMatches(playerId, window.cutoff);
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => FutureBuilder<List<PlayerMatchLine>>(
        future: future,
        builder: (context, snap) {
          final list = snap.data ?? const <PlayerMatchLine>[];
          final total = list.fold(0, (s, m) => s + m.points);
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppText.h(18)),
                        Text(
                          subtitle ?? '$team · ${window.label}',
                          style: AppText.body(12, color: AppColors.neutral700),
                        ),
                      ],
                    ),
                  ),
                  if (snap.hasData) Text('$total', style: AppText.h(34, color: AppColors.accent)),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.hasError)
                Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger))
              else if (!snap.hasData)
                Padding(padding: const EdgeInsets.all(24), child: const SkeletonList())
              else if (list.isEmpty)
                Text('ملعبش في الجولة دي', style: AppText.body(13, color: AppColors.neutral600))
              else
                for (final m in list) _match(m, team),
            ],
          );
        },
      ),
    ),
  );
}

Widget _match(PlayerMatchLine m, String team) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('ضد ${m.opponentOf(team)}', style: AppText.h(14))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.sm),
              child: Text(
                m.finished ? m.score : (m.dateTime.isAfter(DateTime.now()) ? 'لسه' : '🔴 ${m.score}'),
                style: AppText.h(12, color: AppColors.white),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              m.points > 0 ? '+${m.points}' : '${m.points}',
              style: AppText.h(18, color: m.points < 0 ? AppColors.danger : AppColors.accent),
            ),
          ],
        ),
        Text(
          '${m.teams.join(' × ')} · ${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)}',
          style: AppText.body(10, color: AppColors.neutral600),
        ),
        if (m.items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('لعب ومجابش نقط', style: AppText.body(11, color: AppColors.neutral600)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in m.items)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.divider, width: 1.2),
                    ),
                    child: Text(
                      '${i.label}${i.count > 1 ? ' ×${i.count}' : ''} (${i.points > 0 ? '+${i.points}' : i.points})',
                      style: AppText.body(11),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
