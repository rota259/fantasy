import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pill.dart';

/// هيرو الترتيب العام (أسود).
class LeaguesHero extends StatelessWidget {
  const LeaguesHero({super.key, this.rank = '12,480'});
  final String rank;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ترتيبك العام',
                  style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 2),
              Text(rank, style: AppText.h(44, color: AppColors.white, height: 0.9)),
            ],
          ),
          const SizedBox(width: 14),
          const Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Pill.accent('▲ 3,412 هذا الأسبوع'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// تبويبات فرعية للدوريات.
class LeagueSubTabs extends StatelessWidget {
  const LeagueSubTabs({super.key});
  static const _tabs = ['دورياتي', 'عام', 'مناطق'];
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: i == 0 ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(_tabs[i],
                    style: AppText.h(12, color: i == 0 ? AppColors.accent : AppColors.ink)),
              ),
            ),
        ],
      ),
    );
  }
}

/// صف في جدول الترتيب.
class StandingRow extends StatelessWidget {
  const StandingRow({super.key, required this.rank, required this.name, required this.pts, this.me = false});
  final String rank, name, pts;
  final bool me;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: me ? AppColors.accent100 : null,
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(rank,
                style: AppText.h(14, color: me ? AppColors.accent : AppColors.neutral500)),
          ),
          Expanded(child: Text(name, style: AppText.h(13))),
          Text(pts, style: AppText.h(14)),
        ],
      ),
    );
  }
}
