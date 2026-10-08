import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/fx/confetti.dart';
import '../../core/widgets/fx/effects.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/pentagon_avatar.dart';
import '../players/data/models/player.dart';

/// لحظة الجول: الشاشة تضلم وتتهز، صورة اللاعب تكبر في النص، confetti، والنقط بتعدّ (+١٠ لو كابتن).
/// بتقفل لوحدها بعد ٣.٥ ثانية أو بالضغط.
Future<void> showGoalCelebration(
  BuildContext context, {
  required Player player,
  required int points,
  bool captain = false,
  String? match,
}) {
  HapticFeedback.heavyImpact();
  Future.delayed(const Duration(milliseconds: 180), HapticFeedback.heavyImpact);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'goal',
    barrierColor: Colors.black.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (c, _, _) => _GoalView(player: player, points: points, captain: captain, match: match),
  );
}

class _GoalView extends StatefulWidget {
  const _GoalView({required this.player, required this.points, required this.captain, this.match});
  final Player player;
  final int points;
  final bool captain;
  final String? match;

  @override
  State<_GoalView> createState() => _GoalViewState();
}

class _GoalViewState extends State<_GoalView> {
  Timer? _close;

  @override
  void initState() {
    super.initState();
    _close = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _close?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            const Positioned.fill(child: ConfettiBurst(count: 90)),
            Center(
              child: Shake(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('جوووول ⚽', style: AppText.h(40, color: AppColors.white)),
                    const SizedBox(height: 18),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: Motion.reduced(context) ? 1 : 0.2, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (_, s, c) => Transform.scale(scale: s, child: c),
                      child: PulseGlow(
                        color: const Color(0xFFF2C14E),
                        child: PentagonAvatar(
                          initials: p.initials,
                          photoUrl: p.imageUrl,
                          size: 150,
                          verified: p.isVerified,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(p.name, style: AppText.h(26, color: AppColors.white)),
                    if (widget.match != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(widget.match!, style: AppText.body(13, color: AppColors.neutral300)),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('+', style: AppText.h(44, color: AppColors.accent400)),
                        CountUp(
                          value: widget.points,
                          style: AppText.h(54, color: AppColors.accent400),
                        ),
                      ],
                    ),
                    if (widget.captain)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2C14E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('كابتن ×٢ 🔥', style: AppText.h(13, color: AppColors.black)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
