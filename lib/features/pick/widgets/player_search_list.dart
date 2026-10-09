import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../players/data/models/player.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/theme/app_spacing.dart';

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
        // كل فريق لوحده وتحته لاعيبته (الأعلى نقط الأول)
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final e in _byTeam(list).entries) ...[
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.key, style: AppText.h(13, color: AppColors.accent700)),
                      ),
                      Text('${e.value.length}', style: AppText.body(11, color: AppColors.accent700)),
                    ],
                  ),
                ),
                for (final p in e.value) _row(p),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// الفرق بالأبجدية، واللاعيبة جوه كل فريق بترتيب القايمة (النقط).
  static Map<String, List<Player>> _byTeam(List<Player> list) {
    final map = <String, List<Player>>{};
    for (final p in list) {
      map.putIfAbsent(p.team.trim().isEmpty ? 'من غير فريق' : p.team, () => []).add(p);
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  Widget _row(Player p) => Pressable(
    behavior: HitTestBehavior.opaque,
    onTap: () => widget.onPick(p),
    child: Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: AppDecor.tile,
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
