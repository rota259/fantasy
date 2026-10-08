import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../../players/data/models/player.dart';
import '../cubit/round_pick_cubit.dart';
import '../../../core/widgets/fx/effects.dart';
import '../../../core/widgets/fx/flips.dart';
import '../../../core/widgets/motion.dart';
import 'points_pop.dart';

/// ملعب خماسي: ٥ نقاط للأساسيين (حارس + ٤ من أي فرق) + ٢ احتياطي تحت.
/// النقطة الفاضية عليها علامة +، والمليانة عليها اللاعب وشارة C/V.
class PickPitch extends StatelessWidget {
  const PickPitch({
    super.key,
    required this.state,
    required this.onSlotTap,
    required this.onPlayerTap,
    this.pointsFor,
    this.liveTeams = const {},
    this.onSwap,
    this.onMoveTo,
    this.entryKey,
  });

  final RoundPickState state;
  final void Function(String kind) onSlotTap; // gk · out · bench
  final void Function(Player p) onPlayerTap;

  /// لو متحدّد: بيظهر جنب كل لاعب نقطه (للعرض — شاشة تفاصيل النقط).
  final Map<String, int>? pointsFor;

  /// الفرق اللي بتلعب ماتش دلوقتي — لاعيبتها بتنبض بلون مختلف وقت الماتش بس.
  final Set<String> liveTeams;

  /// السحب والإفلات (لو التعديل مسموح): لاعب على لاعب = تبديل · لاعب على مكان فاضي = ينتقل له.
  final void Function(String fromId, String toId)? onSwap;
  final void Function(String fromId, String kind)? onMoveTo;

  /// بيتغيّر بعد الحفظ → اللاعيبة يدخلوا الملعب واحد ورا التاني.
  final int? entryKey;

  bool get _draggable => onSwap != null;

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
      _token(50, 86, at(gk, 0), 'gk', 0),
      _token(29, 20, at(out, 0), 'out', 1),
      _token(71, 20, at(out, 1), 'out', 2),
      _token(16, 60, at(out, 2), 'out', 3),
      _token(84, 60, at(out, 3), 'out', 4),
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
              Expanded(child: _benchCell(at(bench, 0), 5)),
              const SizedBox(width: 10),
              Expanded(child: _benchCell(at(bench, 1), 6)),
            ],
          ),
        ),
      ],
    );
  }

  PitchToken _token(double l, double t, Player? p, String kind, [int order = 0]) => PitchToken(
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
        child: _entry(
          order,
          _drop(p, kind, p == null ? _plus(() => onSlotTap(kind)) : _filled(p, () => onPlayerTap(p))),
        ),
      ),
    ),
  );

  Widget _entry(int order, Widget child) => entryKey == null
      ? child
      : FadeSlideIn(key: ValueKey('$entryKey-$order'), index: order * 2, offset: 40, child: child);

  /// هدف إفلات: على لاعب = تبديل، على مكان فاضي = ينتقل له.
  Widget _drop(Player? p, String kind, Widget child) {
    if (!_draggable) return child;
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != p?.id,
      onAcceptWithDetails: (d) {
        HapticFeedback.selectionClick();
        p == null ? onMoveTo?.call(d.data, kind) : onSwap!(d.data, p.id);
      },
      builder: (_, hover, _) => AnimatedScale(scale: hover.isEmpty ? 1 : 1.15, duration: Motion.fast, child: child),
    );
  }

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
    final body = _player(p, onTap);
    if (!_draggable) return body;
    return LongPressDraggable<String>(
      data: p.id,
      onDragStarted: HapticFeedback.mediumImpact,
      feedback: Material(
        type: MaterialType.transparency,
        child: Transform.scale(
          scale: 1.15,
          child: PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: 52, verified: p.isVerified),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: body),
      child: body,
    );
  }

  Widget _player(Player p, VoidCallback onTap) {
    final badge = state.captainId == p.id ? 'C' : (state.viceId == p.id ? 'V' : null);
    final live = liveTeams.contains(p.team);
    final avatar = PulseGlow(
      enabled: live,
      color: AppColors.danger,
      child: PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: 48, verified: p.isVerified),
    );
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
                badge == 'C' ? SpinRing(size: 48, child: avatar) : avatar,
                Positioned(
                  top: -6,
                  right: -6,
                  // الكابتن/البديل: الشارة بتتقلب لما تتغيّر
                  child: FlipSwitcher(
                    child: badge == null
                        ? const SizedBox(key: ValueKey('none'), width: 20, height: 20)
                        : Container(
                            key: ValueKey(badge),
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: badge == 'C' ? const Color(0xFFF2C14E) : AppColors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              badge,
                              style: AppText.h(9, color: badge == 'C' ? AppColors.black : AppColors.white),
                            ),
                          ),
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
            if (liveTeams.contains(p.team)) _live(),
            if (pointsFor != null) PointsPop(value: pointsFor![p.id] ?? 0),
          ],
        ),
      ),
    );
  }

  /// شارة "بيلعب دلوقتي".
  Widget _live() => Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(color: AppColors.danger, borderRadius: AppRadius.sm),
    child: Text('● لايف', style: AppText.h(8, color: AppColors.white)),
  );

  /// مكان احتياطي: هدف إفلات + اللاعب نفسه بيتسحب + دخول متتابع.
  Widget _benchCell(Player? p, int order) {
    Widget slot = _benchSlot(p);
    if (_draggable && p != null) {
      slot = LongPressDraggable<String>(
        data: p.id,
        onDragStarted: HapticFeedback.mediumImpact,
        feedback: Material(
          type: MaterialType.transparency,
          child: PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: 48),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: slot),
        child: slot,
      );
    }
    return _entry(order, _drop(p, 'bench', slot));
  }

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
          color: liveTeams.contains(p.team) ? AppColors.danger.withValues(alpha: 0.08) : null,
          border: Border.all(
            color: liveTeams.contains(p.team) ? AppColors.danger : AppColors.line,
            width: liveTeams.contains(p.team) ? 1.6 : 1.2,
          ),
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
