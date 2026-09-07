import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../../players/data/models/player.dart';
import '../cubit/match_pick_cubit.dart';

/// ملعب خماسي: ٥ نقاط للأساسيين (حارس + ٢ لكل فريق) + ٢ احتياطي تحت.
/// النقطة الفاضية عليها علامة +، والمليانة عليها اللاعب وشارة C/V.
class PickPitch extends StatelessWidget {
  const PickPitch({
    super.key,
    required this.state,
    required this.teamA,
    required this.teamB,
    required this.onSlotTap,
    required this.onPlayerTap,
  });

  final MatchPickState state;
  final String teamA;
  final String teamB;
  final void Function(String kind) onSlotTap;
  final void Function(Player p) onPlayerTap;

  List<Player> _starting(bool Function(Player) test) {
    final out = <Player>[];
    state.sel.forEach((id, st) {
      final p = state.playerById(id);
      if (st == 'starting' && p != null && test(p)) out.add(p);
    });
    return out;
  }

  List<Player> get _bench {
    final out = <Player>[];
    state.sel.forEach((id, st) {
      final p = state.playerById(id);
      if (st == 'bench' && p != null) out.add(p);
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final gk = _starting((p) => p.position == 'GK');
    final a = _starting((p) => p.position != 'GK' && p.team == teamA);
    final b = _starting((p) => p.position != 'GK' && p.team == teamB);

    Player? at(List<Player> l, int i) => i < l.length ? l[i] : null;

    final tokens = [
      _token(50, 86, at(gk, 0), 'gk'),
      _token(16, 60, at(a, 0), 'teamA'),
      _token(29, 20, at(a, 1), 'teamA'),
      _token(71, 20, at(b, 0), 'teamB'),
      _token(84, 60, at(b, 1), 'teamB'),
    ];

    final bench = _bench;
    return Column(
      children: [
        PentagonPitch(height: 360, tokens: tokens),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Row(children: [
            Text('الاحتياطي', style: AppText.kicker(color: AppColors.accent)),
            const Spacer(),
            Text('${bench.length}/2', style: AppText.h(12)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Expanded(child: _benchSlot(at(bench, 0))),
            const SizedBox(width: 10),
            Expanded(child: _benchSlot(at(bench, 1))),
          ]),
        ),
      ],
    );
  }

  PitchToken _token(double l, double t, Player? p, String kind) => PitchToken(
        leftPct: l,
        topPct: t,
        child: p == null ? _plus(() => onSlotTap(kind)) : _filled(p, () => onPlayerTap(p)),
      );

  Widget _plus(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46, height: 46, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.night2,
            border: Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 2),
          ),
          child: Text('+', style: AppText.h(22, color: AppColors.white)),
        ),
      );

  Widget _filled(Player p, VoidCallback onTap) {
    final badge = state.captainId == p.id ? 'C' : (state.viceId == p.id ? 'V' : null);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 46, height: 46, alignment: Alignment.center,
              color: AppColors.accent,
              child: Text(p.initials, style: AppText.h(16, color: AppColors.white)),
            ),
            if (badge != null)
              Positioned(
                top: -6, right: -6,
                child: Container(
                  width: 18, height: 18, alignment: Alignment.center,
                  color: AppColors.black,
                  child: Text(badge, style: AppText.h(9, color: AppColors.white)),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(p.name,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppText.h(10, color: AppColors.white)),
        ]),
      ),
    );
  }

  Widget _benchSlot(Player? p) {
    if (p == null) {
      return GestureDetector(
        onTap: () => onSlotTap('bench'),
        child: Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 2)),
          child: Text('+ احتياطي', style: AppText.h(12, color: AppColors.neutral600)),
        ),
      );
    }
    return GestureDetector(
      onTap: () => onPlayerTap(p),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
        child: Row(children: [
          Container(
            width: 28, height: 28, alignment: Alignment.center,
            color: AppColors.neutral200,
            child: Text(p.initials, style: AppText.h(11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(12)),
          ),
        ]),
      ),
    );
  }
}
