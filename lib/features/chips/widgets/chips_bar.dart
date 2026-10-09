import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/effects.dart';
import '../cubit/chips_cubit.dart';
import '../data/chip_type.dart';
import '../data/models/chip_status.dart';
import '../../../core/widgets/motion.dart';

/// الكروت الأربعة في شاشة التشكيلة: الباقي من كل كارت + التفعيل (مبيتلغيش).
class ChipsBar extends StatelessWidget {
  const ChipsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChipsCubit, ChipsState>(
      builder: (context, s) {
        if (!s.loaded || s.chips.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الكروت · CHIPS', style: AppText.kicker()),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < s.chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _ChipCard(chip: s.chips[i], busy: s.busy),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard({required this.chip, required this.busy});
  final ChipStatus chip;
  final bool busy;

  /// لون هادي لكل كارت.
  static Color _hue(ChipType t) => switch (t) {
    ChipType.triple => const Color(0xFFE0A526),
    ChipType.benchBoost => const Color(0xFF1FA39A),
    ChipType.wildcard => const Color(0xFF7C5CD6),
    ChipType.doubleUp => const Color(0xFFE5743A),
  };

  @override
  Widget build(BuildContext context) {
    final on = chip.active;
    final available = chip.canActivate && !busy;
    final dim = !on && !available;
    final hue = dim ? AppColors.neutral400 : _hue(chip.type);
    final sub = on ? 'مفعّل ✓' : (chip.blocked ?? (chip.left == 0 ? 'خلص' : 'باقي ${chip.left}'));
    return Pressable(
      onTap: () => _open(context),
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: on
                ? [hue, Color.lerp(hue, Colors.black, 0.25)!]
                : [hue.withValues(alpha: 0.16), hue.withValues(alpha: 0.06)],
          ),
          border: Border.all(color: hue.withValues(alpha: on ? 0 : 0.35)),
          boxShadow: [
            if (!dim)
              BoxShadow(
                color: hue.withValues(alpha: on ? 0.45 : 0.15),
                blurRadius: on ? 16 : 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            PulseGlow(
              enabled: on,
              color: Colors.white,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? Colors.white.withValues(alpha: 0.25) : hue.withValues(alpha: 0.18),
                ),
                child: Icon(chip.type.icon, size: 20, color: on ? Colors.white : hue),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              chip.type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h(10, color: on ? Colors.white : (dim ? AppColors.neutral600 : AppColors.ink)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: on ? Colors.white.withValues(alpha: 0.25) : hue.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.h(8, color: on ? Colors.white : (dim ? AppColors.neutral600 : hue)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<ChipsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text(chip.type.label, style: AppText.h(16)),
        content: Text(
          '${chip.type.description}\n\n'
          '${chip.active
              ? 'الكارت ده مفعّل في الجولة دي.'
              : chip.canActivate
              ? '⚠️ لما تفعّله مش هتقدر تلغيه، ومش هتقدر تستخدم كارت تاني في الجولة دي.'
              : 'مش متاح: ${chip.blocked ?? 'خلص'}'}',
          style: AppText.body(13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('رجوع')),
          if (chip.canActivate)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('فعّل', style: AppText.h(13, color: AppColors.accent)),
            ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await cubit.activate(chip.type);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'اتفعّل ${chip.type.label} ✓'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
      ),
    );
  }
}
