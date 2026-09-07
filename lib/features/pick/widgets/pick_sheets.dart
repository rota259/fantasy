import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/models/player.dart';
import '../cubit/match_pick_cubit.dart';

/// قائمة اللاعيبة المتاحين للنقطة دي (من تشكيلة المدير، غير المختارين).
List<Player> _eligible(MatchPickState s, String kind, String teamA, String teamB) {
  return s.players.where((p) {
    if (s.sel.containsKey(p.id)) return false;
    switch (kind) {
      case 'gk':
        return p.position == 'GK';
      case 'teamA':
        return p.position != 'GK' && p.team == teamA;
      case 'teamB':
        return p.position != 'GK' && p.team == teamB;
      default:
        return true; // احتياطي: أي لاعب
    }
  }).toList();
}

/// شيت اختيار لاعب لنقطة فاضية.
Future<void> showAddPlayerSheet(
  BuildContext context,
  MatchPickCubit cubit,
  MatchPickState s,
  String kind,
  String teamA,
  String teamB,
) {
  final list = _eligible(s, kind, teamA, teamB);
  return _listSheet(context, 'اختر لاعب', list, (p) {
    cubit.setStatus(p.id, kind == 'bench' ? 'bench' : 'starting');
    Navigator.pop(context);
  });
}

/// شيت خيارات لاعب مختار: كابتن / كابتن احتياطي / تبديل / شيل.
Future<void> showPlayerOptionsSheet(
  BuildContext context,
  MatchPickCubit cubit,
  MatchPickState s,
  Player p,
) {
  final starting = s.sel[p.id] == 'starting';
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _title(p.name),
        if (starting) ...[
          _option(context, 'اعمله كابتن (×٢)', () => cubit.setCaptain(p.id)),
          _option(context, 'اعمله كابتن احتياطي', () => cubit.setVice(p.id)),
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
      ]),
    ),
  );
}

/// شيت اختيار الطرف التاني للتبديل.
void _swapSheet(BuildContext context, MatchPickCubit cubit, MatchPickState s, Player p,
    {required bool wantStarting}) {
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

Future<void> _listSheet(
  BuildContext context,
  String title,
  List<Player> players,
  void Function(Player) onPick,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _title(title),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('مفيش لاعيبة متاحة', style: AppText.body(13, color: AppColors.neutral600)),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in players)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
                      child: Row(children: [
                        Container(
                          width: 30, height: 30, alignment: Alignment.center,
                          color: AppColors.neutral200,
                          child: Text(p.initials, style: AppText.h(11)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(p.name, style: AppText.h(13))),
                        Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ]),
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

Widget _option(BuildContext context, String label, VoidCallback onTap,
    {bool danger = false, bool keepOpen = false}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      if (!keepOpen) Navigator.pop(context);
      onTap();
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Text(label, style: AppText.h(14, color: danger ? AppColors.danger : AppColors.ink)),
    ),
  );
}
