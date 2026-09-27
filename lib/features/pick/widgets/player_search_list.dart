import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../players/data/models/player.dart';
import '../../../core/widgets/motion.dart';

/// قايمة لاعيبة ببحث (بالاسم أو الفريق) — لاعيبة المنطقة ممكن يبقوا كتير.
class PlayerSearchList extends StatefulWidget {
  const PlayerSearchList({super.key, required this.players, required this.onPick});

  final List<Player> players;
  final void Function(Player) onPick;

  @override
  State<PlayerSearchList> createState() => _PlayerSearchListState();
}

class _PlayerSearchListState extends State<PlayerSearchList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = [
      for (final p in widget.players)
        if (_q.isEmpty || p.name.contains(_q) || p.team.contains(_q)) p,
    ]..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.players.length > 6)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _q = v.trim()),
              style: AppText.body(14),
              decoration: const InputDecoration(
                hintText: 'دوّر بالاسم أو الفريق…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('مفيش لاعيبة متاحة', style: AppText.body(13, color: AppColors.neutral600)),
          ),
        Flexible(child: ListView(shrinkWrap: true, children: [for (final p in list) _row(p)])),
      ],
    );
  }

  Widget _row(Player p) => Pressable(
    behavior: HitTestBehavior.opaque,
    onTap: () => widget.onPick(p),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          InitialsTile(p.initials, size: 32, photoUrl: p.imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: AppText.h(13)),
                Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
              ],
            ),
          ),
          Text('${p.totalPoints}', style: AppText.h(13, color: AppColors.accent)),
        ],
      ),
    ),
  );
}
