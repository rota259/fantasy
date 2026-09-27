import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../cubit/chips_cubit.dart';
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
                    if (i > 0) const SizedBox(width: 6),
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

  @override
  Widget build(BuildContext context) {
    final on = chip.active;
    final available = chip.canActivate && !busy;
    final sub = on ? 'مفعّل ✓' : (chip.blocked ?? (chip.left == 0 ? 'خلص' : 'باقي ${chip.left}'));
    return Pressable(
      onTap: () => _open(context),
      child: Opacity(
        opacity: on || available ? 1 : 0.5,
        child: Column(
          children: [
            PentagonIcon(
              size: 50,
              fill: on ? AppColors.accent : AppColors.white,
              stroke: on ? AppColors.accent : AppColors.black,
              child: Icon(chip.type.icon, size: 20, color: on ? AppColors.white : AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(chip.type.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(10)),
            Text(
              sub,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: AppText.body(8, color: on ? AppColors.accent : AppColors.neutral700),
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
