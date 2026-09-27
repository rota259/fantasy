import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/models/player.dart';
import '../cubit/round_pick_cubit.dart';
import 'player_search_list.dart';
import '../../../core/widgets/motion.dart';

/// اللاعيبة المتاحين للنقطة دي (من كل فرق المنطقة، غير المختارين).
List<Player> _eligible(RoundPickState s, String kind) => s.players.where((p) {
  if (s.sel.containsKey(p.id)) return false;
  return switch (kind) {
    'gk' => p.position == 'GK',
    'out' => p.position != 'GK',
    _ => true, // احتياطي: أي لاعب
  };
}).toList();

/// شيت اختيار لاعب لنقطة فاضية (مع بحث بالاسم أو الفريق).
Future<void> showAddPlayerSheet(BuildContext context, RoundPickCubit cubit, RoundPickState s, String kind) {
  final title = switch (kind) {
    'gk' => 'اختار حارس',
    'out' => 'اختار لاعب',
    _ => 'اختار احتياطي',
  };
  return _listSheet(context, title, _eligible(s, kind), (p) {
    cubit.setStatus(p.id, kind == 'bench' ? 'bench' : 'starting');
    Navigator.pop(context);
  });
}

/// شيت خيارات لاعب مختار: كابتن / كابتن بديل / تبديل / شيل.
Future<void> showPlayerOptionsSheet(BuildContext context, RoundPickCubit cubit, RoundPickState s, Player p) {
  final starting = s.sel[p.id] == 'starting';
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _title('${p.name} · ${p.team}'),
          if (starting) ...[
            _option(context, 'اعمله كابتن (×٢)', () => cubit.setCaptain(p.id)),
            _option(context, 'اعمله كابتن بديل', () => cubit.setVice(p.id)),
            _option(context, 'بدّله باحتياطي', () {
              Navigator.pop(context);
              _swapSheet(context, cubit, s, p, wantStarting: false);
            }, keepOpen: true),
          ] else
            _option(context, 'بدّله بأساسي', () {
              Navigator.pop(context);
              _swapSheet(context, cubit, s, p, wantStarting: true);
            }, keepOpen: true),
          _option(context, 'شيله من التشكيلة', () => cubit.removePick(p.id), danger: true),
        ],
      ),
    ),
  );
}

/// شيت اختيار الطرف التاني للتبديل.
void _swapSheet(BuildContext context, RoundPickCubit cubit, RoundPickState s, Player p, {required bool wantStarting}) {
  final target = wantStarting ? 'starting' : 'bench';
  final list = <Player>[];
  s.sel.forEach((id, st) {
    final q = s.playerById(id);
    if (st == target && q != null) list.add(q);
  });
  _listSheet(context, wantStarting ? 'بدّل مع أساسي' : 'بدّل مع احتياطي', list, (q) {
    cubit.swap(p.id, q.id);
    Navigator.pop(context);
  });
}

Future<void> _listSheet(BuildContext context, String title, List<Player> players, void Function(Player) onPick) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _title(title),
            Flexible(
              child: PlayerSearchList(players: players, onPick: onPick),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _title(String t) => Container(
  width: double.infinity,
  color: AppColors.black,
  padding: const EdgeInsets.all(14),
  child: Text(t, style: AppText.h(15, color: AppColors.white)),
);

Widget _option(BuildContext context, String label, VoidCallback onTap, {bool danger = false, bool keepOpen = false}) {
  return Pressable(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      if (!keepOpen) Navigator.pop(context);
      onTap();
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Text(label, style: AppText.h(14, color: danger ? AppColors.danger : AppColors.ink)),
    ),
  );
}
