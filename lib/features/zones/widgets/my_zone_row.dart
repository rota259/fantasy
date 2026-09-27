import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../data/zone.dart';
import '../data/zones_repository.dart';
import 'zone_picker_sheet.dart';
import '../../../core/widgets/motion.dart';

/// "منطقتي: بدر · القاهرة" في الحساب — دوس تغيّرها (مرة كل ٣٠ يوم).
class MyZoneRow extends StatelessWidget {
  const MyZoneRow({super.key, required this.zoneId, this.editable = true});
  final int? zoneId;
  final bool editable; // المدير: للعرض بس

  Future<void> _change(BuildContext context, Zone? current) async {
    final z = await showZonePicker(context);
    if (z == null || z.id == current?.id || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('تنقل لـ ${z.name}؟', style: AppText.h(16)),
        content: Text(
          'هتشوف ماتشات ونجوم ${z.name} بس، وتعمل تشكيلاتك منها. مش هتقدر تغيّر تاني قبل ٣٠ يوم.',
          style: AppText.body(13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('انقل')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthCubit>();
    try {
      await context.read<ZonesRepository>().setMine(z.id);
      await auth.refresh(); // الشاشات بتتبني من جديد بالمنطقة الجديدة
      messenger.showSnackBar(SnackBar(content: Text('منطقتك بقت ${z.label} ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Zone?>(
      future: context.read<ZonesRepository>().byId(zoneId),
      builder: (context, snap) => Pressable(
        behavior: HitTestBehavior.opaque,
        onTap: editable ? () => _change(context, snap.data) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: AppColors.ink),
              const SizedBox(width: 12),
              Expanded(child: Text('منطقتي: ${snap.data?.label ?? '…'}', style: AppText.h(13))),
              if (editable) Text('غيّر ›', style: AppText.body(12, color: AppColors.neutral700)),
            ],
          ),
        ),
      ),
    );
  }
}
