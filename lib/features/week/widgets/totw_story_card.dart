import 'package:flutter/material.dart';

import '../../../core/share/story_frame.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/formation_pitch.dart';
import '../data/models/week_player.dart';
import '../data/team_of_week.dart';
import 'totw_pitch.dart';

/// كارت story لتشكيلة الجولة: النجم كبير فوق والأربعة + الحارس تحته.
class TotwStoryCard extends StatelessWidget {
  const TotwStoryCard({super.key, required this.team, required this.label, this.refCode});
  final List<WeekPlayer> team;
  final String label;
  final String? refCode;

  @override
  Widget build(BuildContext context) {
    final star = TeamOfWeek.starOf(team);
    final rest = team.where((p) => p != star).toList();
    Widget player(WeekPlayer p, {bool big = false}) => StoryPlayer(
      name: p.name,
      points: p.points,
      star: big,
      photo: GoldAvatar(player: p, size: big ? 112 : 54),
    );
    return StoryFrame(
      kicker: label,
      refCode: refCode,
      colors: const [PitchColors.grass, PitchColors.forest],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: StoryColors.gold, size: 26),
                const SizedBox(width: 6),
                Text('تشكيلة الجولة', style: AppText.h(26, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (star != null) ...[
            player(star, big: true),
            const SizedBox(height: 6),
            const StoryPill('نجم الجولة', icon: Icons.star_rounded, color: StoryColors.gold),
          ],
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final p in rest.take(4)) Expanded(child: player(p))],
          ),
        ],
      ),
    );
  }
}
