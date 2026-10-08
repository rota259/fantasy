import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/effects.dart';
import '../../matches/widgets/match_format.dart';
import '../data/models/tournament.dart';

/// كارت البطولة فوق: النظام · البداية · الجايزة والراعي — ولو خلصت: البطل بكاس بيلف.
class TournamentHeader extends StatelessWidget {
  const TournamentHeader({super.key, required this.t});
  final Tournament t;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.black, AppColors.night]),
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          t.isFinished ? CoinSpin(turns: 3, child: Text('🏆', style: AppText.h(34))) : Text('⚽', style: AppText.h(30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.isFinished && t.champion != null)
                  Text('البطل: ${t.champion}', style: AppText.h(17, color: const Color(0xFFF2C14E)))
                else
                  Text(t.statusLabel, style: AppText.h(14, color: AppColors.accent400)),
                Text(
                  '${t.formatLabel} · ${t.teamCount} فرق · من ${arabicWeekday(t.startsAt)} ${t.startsAt.day}/${t.startsAt.month}',
                  style: AppText.body(11, color: AppColors.neutral300),
                ),
                if (t.prize != null || t.sponsor != null)
                  Text(
                    [if (t.prize != null) '🎁 ${t.prize}', if (t.sponsor != null) 'برعاية ${t.sponsor}'].join(' · '),
                    style: AppText.h(11, color: AppColors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
