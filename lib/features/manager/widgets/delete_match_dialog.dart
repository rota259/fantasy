import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/data/models/game_match.dart';

/// تأكيد حذف ماتش (بيتمسح معاه التشكيلة والأحداث).
Future<bool> confirmDeleteMatch(BuildContext context, GameMatch m) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bg,
      title: Text('حذف الماتش', style: AppText.h(16)),
      content: Text(
        'متأكد إنك عايز تحذف «${m.teamA} ضد ${m.teamB}»؟\nهيتمسح معاه التشكيلة والأحداث.',
        style: AppText.body(13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('إلغاء', style: AppText.h(13, color: AppColors.neutral700)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('احذف', style: AppText.h(13, color: AppColors.danger)),
        ),
      ],
    ),
  );
  return ok == true;
}
