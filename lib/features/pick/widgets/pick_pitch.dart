import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../../players/data/models/player.dart';
import '../cubit/round_pick_cubit.dart';
import '../../../core/widgets/motion.dart';

/// ملعب خماسي: ٥ نقاط للأساسيين (حارس + ٤ من أي فرق) + ٢ احتياطي تحت.
/// النقطة الفاضية عليها علامة +، والمليانة عليها اللاعب وشارة C/V.
class PickPitch extends StatelessWidget {
  const PickPitch({super.key, required this.state, required this.onSlotTap, required this.onPlayerTap, this.pointsFor});

  final RoundPickState state;
  final void Function(String kind) onSlotTap; // gk · out · bench
  final void Function(Player p) onPlayerTap;

  /// لو متحدّد: بيظهر جنب كل لاعب نقطه (للعرض — شاشة تفاصيل النقط).
  final Map<String, int>? pointsFor;

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
    final out = _starting((p) => p.position != 'GK');

    Player? at(List<Player> l, int i) => i < l.length ? l[i] : null;

    final tokens = [
      _token(50, 86, at(gk, 0), 'gk'),
      _token(29, 20, at(out, 0), 'out'),
      _token(71, 20, at(out, 1), 'out'),
      _token(16, 60, at(out, 2), 'out'),
      _token(84, 60, at(out, 3), 'out'),
    ];

    final bench = _bench;
    return Column(
      children: [
        PentagonPitch(height: 360, tokens: tokens),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Row(
            children: [
              Text('الاحتياطي', style: AppText.kicker(color: AppColors.accent)),
              const Spacer(),
              Text('${bench.length}/2', style: AppText.h(12)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(child: _benchSlot(at(bench, 0))),
              const SizedBox(width: 10),
              Expanded(child: _benchSlot(at(bench, 1))),
            ],
          ),
        ),
      ],
    );
  }

  PitchToken _token(double l, double t, Player? p, String kind) => PitchToken(
    leftPct: l,
    topPct: t,
    // اللاعب بيدخل مكانه بتكبير خفيف (والمكان الفاضي بيرجع كده برضه)
    child: AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, a) => ScaleTransition(
        scale: a,
        child: FadeTransition(opacity: a, child: child),
      ),
      child: KeyedSubtree(
        key: ValueKey(p?.id ?? 'empty-$l-$t'),
        child: p == null ? _plus(() => onSlotTap(kind)) : _filled(p, () => onPlayerTap(p)),
      ),
    ),
  );

  Widget _plus(VoidCallback onTap) => Pressable(
    onTap: onTap,
    child: PentagonIcon(
      size: 48,
      fill: AppColors.night2,
      stroke: AppColors.white.withValues(alpha: 0.5),
      child: Text('+', style: AppText.h(22, color: AppColors.white)),
    ),
  );

  Widget _filled(Player p, VoidCallback onTap) {
    final badge = state.captainId == p.id ? 'C' : (state.viceId == p.id ? 'V' : null);
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: 48, verified: p.isVerified),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      color: AppColors.black,
                      child: Text(badge, style: AppText.h(9, color: AppColors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h(10, color: AppColors.white),
            ),
            if (pointsFor != null) _pts(pointsFor![p.id] ?? 0),
          ],
        ),
      ),
    );
  }

  /// شارة النقط تحت اللاعب.
  Widget _pts(int n) => Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: n > 0 ? AppColors.accent : (n < 0 ? AppColors.danger : AppColors.neutral600),
      borderRadius: AppRadius.sm,
    ),
    child: Text('$n', style: AppText.h(11, color: AppColors.white)),
  );

  Widget _benchSlot(Player? p) {
    if (p == null) {
      return Pressable(
        onTap: () => onSlotTap('bench'),
        child: Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.divider, width: 2),
          ),
          child: Text('+ احتياطي', style: AppText.h(12, color: AppColors.neutral600)),
        ),
      );
    }
    return Pressable(
      onTap: () => onPlayerTap(p),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Row(
          children: [
            PentagonAvatar(
              initials: p.initials,
              photoUrl: p.imageUrl,
              size: 30,
              background: AppColors.neutral200,
              color: AppColors.ink,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(12)),
            ),
            // الاحتياطي نقطه بتظهر بس مش بتتحسب
            if (pointsFor != null) Text('${pointsFor![p.id] ?? 0}', style: AppText.h(12, color: AppColors.neutral500)),
          ],
        ),
      ),
    );
  }
}
