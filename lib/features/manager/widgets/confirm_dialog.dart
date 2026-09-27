import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// ديالوج تأكيد (تأكيد / إلغاء) — بيرجّع true لو أكّد.
Future<bool> confirmDialog(BuildContext context, String title, String body) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bg,
      title: Text(title, style: AppText.h(16)),
      content: Text(body, style: AppText.body(13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
      ],
    ),
  );
  return ok == true;
}
