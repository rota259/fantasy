import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/models/player.dart';
import '../lineup_points.dart';
import '../play_status.dart';

/// سطر لاعب في تفصيل الجولة: اسمه ودوره + نقطه (بالمضاعفة) + عمل إيه + لعب ولا لسه.
class RoundPointRow extends StatelessWidget {
  const RoundPointRow({super.key, required this.row, this.player, this.status});

  final PickPoints row;
  final Player? player;
  final PlayStatus? status; // في الجولة الشغّالة بس

  @override
  Widget build(BuildContext context) {
    final tag = [
      if (row.pick.isCaptain) 'كابتن',
      if (row.pick.isVice) 'كابتن بديل',
      if (row.pick.status == 'bench') row.counted ? 'احتياطي — اتحسب بالكارت' : 'احتياطي — مش محسوب',
    ].join(' · ');
    final st = status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${player?.name ?? 'لاعب'}${tag.isEmpty ? '' : ' · $tag'}',
                  style: AppText.h(14, color: row.counted ? AppColors.ink : AppColors.neutral500),
                ),
              ),
              if (row.multiplier > 1 && row.counted)
                Text('${row.base} × ${row.multiplier} = ', style: AppText.body(12, color: AppColors.neutral700)),
              Text(
                '${row.counted ? row.total : row.base}',
                style: AppText.h(18, color: row.counted ? AppColors.accent : AppColors.neutral500),
              ),
            ],
          ),
          if (st != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(st.label, style: AppText.body(11, color: _statusColor(st.state))),
            ),
          const SizedBox(height: 4),
          if (row.items.isEmpty)
            Text('ملهوش نقط في الجولة دي', style: AppText.body(11, color: AppColors.neutral600))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in row.items)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.divider, width: 1.2),
                    ),
                    child: Text(
                      '${i.label}${i.count > 1 ? ' ×${i.count}' : ''} (${_signed(i.points)})',
                      style: AppText.body(11),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static Color _statusColor(PlayState s) => switch (s) {
    PlayState.live => AppColors.danger,
    PlayState.upcoming => AppColors.info,
    PlayState.played => AppColors.accent700,
    _ => AppColors.neutral600,
  };

  static String _signed(int n) => n > 0 ? '+$n' : '$n';
}
