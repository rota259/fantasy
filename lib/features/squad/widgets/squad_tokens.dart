import 'package:flutter/widgets.dart';

import '../../../core/widgets/pentagon_pitch.dart';
import '../../../core/widgets/player_token.dart';
import '../../players/data/models/player.dart';

/// خانات الملعب الخماسي: (يسار%, أعلى%, المركز المفضّل).
const _slots = [
  (71.0, 20.0, 'FWD'),
  (29.0, 20.0, 'FWD'),
  (84.0, 60.0, 'DEF'),
  (16.0, 60.0, 'DEF'),
  (50.0, 86.0, 'GK'),
];

/// بيحوّل لاعيبة التشكيلة لتوكنات على الملعب.
/// [showPoints] = true في الهوم (شارة نقاط)، false في التشكيل (شارة مركز).
List<PitchToken> squadTokens(
  List<Player> players, {
  required bool showPoints,
  String? captainId,
  void Function(String id)? onRemove,
}) {
  final pool = [...players];
  // الكابتن المختار، وإلا أعلى نقاط أوتوماتيك.
  final capId = (captainId != null && pool.any((p) => p.id == captainId))
      ? captainId
      : (pool.isEmpty ? null : pool.reduce((a, b) => a.totalPoints >= b.totalPoints ? a : b).id);

  final tokens = <PitchToken>[];
  for (final slot in _slots) {
    if (pool.isEmpty) break;
    var idx = pool.indexWhere((p) => p.position == slot.$3);
    if (idx < 0) idx = 0;
    final p = pool.removeAt(idx);
    final isCap = p.id == capId;
    Widget child = PlayerToken(
      number: p.position == 'GK' ? 'GK' : p.initials,
      name: p.name,
      chip: showPoints ? '${p.totalPoints}' : p.positionAr,
      isCaptain: isCap,
      chipAccent: showPoints && isCap,
    );
    if (onRemove != null) {
      child = GestureDetector(onTap: () => onRemove(p.id), child: child);
    }
    tokens.add(PitchToken(leftPct: slot.$1, topPct: slot.$2, child: child));
  }
  return tokens;
}
