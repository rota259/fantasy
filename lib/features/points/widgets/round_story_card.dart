import 'package:flutter/material.dart';

import '../../../core/share/story_frame.dart';
import '../../../core/theme/app_text.dart';
import '../data/round_recap.dart';

/// كارت story لجولتي: النقط كبيرة بالفسفوري + الترتيب + أحسن اختيار + الكابتن.
class RoundStoryCard extends StatelessWidget {
  const RoundStoryCard({super.key, required this.recap, required this.name, required this.label, this.refCode});
  final RoundRecap recap;
  final String name;
  final String label;
  final String? refCode;

  @override
  Widget build(BuildContext context) {
    final r = recap;
    return StoryFrame(
      kicker: label,
      refCode: refCode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.h(22, color: Colors.white),
          ),
          Text('جولتي في الخماسي', style: AppText.body(12, color: Colors.white60)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${r.points}', style: AppText.h(132, color: StoryColors.lime, height: 1)),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Text('نقطة', style: AppText.h(22, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _rank(r),
          const SizedBox(height: 10),
          Row(
            children: [
              if (r.bestName != null)
                Expanded(
                  child: StoryTile(label: 'أحسن اختيار', value: r.bestName!, sub: '${r.bestPoints} نقطة'),
                ),
              if (r.bestName != null && r.captainName != null) const SizedBox(width: 10),
              if (r.captainName != null)
                Expanded(
                  child: StoryTile(
                    label: 'الكابتن ×٢',
                    value: r.captainName!,
                    sub: '${r.captainPoints * 2} نقطة',
                    accent: StoryColors.gold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rank(RoundRecap r) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('#${r.rankNow}', style: AppText.h(34, color: Colors.white, height: 1)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الترتيب العام',
                maxLines: 1,
                softWrap: false,
                style: AppText.kicker(color: StoryColors.lime, size: 10),
              ),
              Text(
                'من ${r.users} لاعب',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: AppText.body(11, color: Colors.white70, height: 1.2),
              ),
            ],
          ),
        ),
        if (r.moved != 0)
          StoryPill(
            r.moved > 0 ? 'طلعت ${r.moved}' : 'نزلت ${-r.moved}',
            icon: r.moved > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            filled: r.moved > 0,
            color: r.moved > 0 ? StoryColors.lime : Colors.white70,
          ),
      ],
    ),
  );
}
