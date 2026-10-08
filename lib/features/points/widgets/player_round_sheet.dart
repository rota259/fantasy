import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/models/player.dart';
import '../../week/data/week_window.dart';
import '../data/player_round_points.dart';
import '../data/points_repository.dart';
import '../play_status.dart';

/// شيت "اللاعب عمل إيه لحد دلوقتي": نقطه + كل حاجة (أهداف · أسيست · تصديات · تدخلات · كروت …).
Future<void> showPlayerRoundSheet(
  BuildContext context, {
  required Player player,
  required int points,
  required List<ScoreItem> items,
  int multiplier = 1,
  PlayStatus? status,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name, style: AppText.h(18)),
                      Text(
                        '${player.team} · ${player.positionAr}',
                        style: AppText.body(12, color: AppColors.neutral700),
                      ),
                      if (status != null)
                        Text(
                          status.label,
                          style: AppText.h(
                            12,
                            color: status.state == PlayState.live ? AppColors.danger : AppColors.info,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('${points * multiplier}', style: AppText.h(34, color: AppColors.accent)),
                    if (multiplier > 1)
                      Text('$points × $multiplier', style: AppText.body(11, color: AppColors.neutral700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'لسه معملش حاجة في الجولة دي',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: AppColors.neutral600),
                ),
              ),
            for (final i in items)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: AppDecor.softDivider,
                child: Row(
                  children: [
                    Expanded(child: Text(i.label, style: AppText.h(14))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: AppRadius.sm),
                      child: Text('×${i.count}', style: AppText.h(12)),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        i.points > 0 ? '+${i.points}' : '${i.points}',
                        textAlign: TextAlign.end,
                        style: AppText.h(14, color: i.points < 0 ? AppColors.danger : AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ),
  );
}

/// نفس الشيت بس بيجيب نقط اللاعب في الجولة من السيرفر (من شاشة التشكيلة).
Future<void> showPlayerRoundSheetFor(BuildContext context, Player player, WeekWindow window) async {
  final repo = context.read<PointsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final pts = (await repo.roundPlayerPoints(window.cutoff, [player.id]))[player.id];
    if (!context.mounted) return;
    await showPlayerRoundSheet(context, player: player, points: pts?.points ?? 0, items: pts?.items ?? const []);
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('تعذّر تحميل تفاصيل اللاعب')));
  }
}
