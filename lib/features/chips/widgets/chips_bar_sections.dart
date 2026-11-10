part of 'chips_bar.dart';

extension _ChipCardSections1 on _ChipCard {
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
              ? 'لما تفعّله مش هتقدر تلغيه، ومش هتقدر تستخدم كارت تاني في الجولة دي.'
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
