import 'package:flutter/material.dart';

import '../../../core/share/story_frame.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../data/models/week_player.dart';
import '../data/team_of_week.dart';

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
      photo: PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: big ? 96 : 54, verified: p.verified),
    );
    return StoryFrame(
      kicker: label,
      refCode: refCode,
      colors: const [Color(0xFF16305A), Color(0xFF0B1426)],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⭐ تشكيلة الجولة', style: AppText.h(20, color: Colors.white)),
          const SizedBox(height: 16),
          if (star != null) player(star, big: true),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: [for (final p in rest) SizedBox(width: 80, child: player(p))],
          ),
        ],
      ),
    );
  }
}
