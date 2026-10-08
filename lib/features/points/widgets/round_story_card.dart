import 'package:flutter/material.dart';

import '../../../core/share/story_frame.dart';
import '../../../core/theme/app_text.dart';
import '../data/round_recap.dart';

/// كارت story لجولتي: النقط كبيرة + الترتيب + أحسن اختيار + الكابتن.
class RoundStoryCard extends StatelessWidget {
  const RoundStoryCard({super.key, required this.recap, required this.name, required this.label, this.refCode});
  final RoundRecap recap;
  final String name;
  final String label;
  final String? refCode;

  @override
  Widget build(BuildContext context) {
    final r = recap;
    const gold = Color(0xFFF2C14E);
    Widget line(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: AppText.body(13, color: Colors.white70)),
          ),
          Text(v, style: AppText.h(14, color: Colors.white)),
        ],
      ),
    );
    return StoryFrame(
      kicker: label,
      refCode: refCode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: AppText.h(20, color: Colors.white)),
          const SizedBox(height: 8),
          Text('${r.points}', style: AppText.h(84, color: const Color(0xFF52C487), height: 1)),
          Text('نقطة في الجولة', style: AppText.h(14, color: Colors.white)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                line('الترتيب العام', '#${r.rankNow}${r.moved > 0 ? '  ⬆${r.moved}' : ''}'),
                if (r.bestName != null) line('أحسن اختيار', '${r.bestName} · ${r.bestPoints}'),
                if (r.captainName != null) line('الكابتن', '${r.captainName} · ${r.captainPoints * 2}'),
              ],
            ),
          ),
          if (r.moved > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('🚀 طلعت ${r.moved} مركز', style: AppText.h(15, color: gold)),
            ),
        ],
      ),
    );
  }
}
