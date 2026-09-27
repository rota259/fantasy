import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// تنبيه "ديدلاين الجولة عدّى" في شاشة الماتش الجديد:
/// الأدمن بيضيف عادي، ومدير المنطقة بيكتب سبب ويبعت طلب للإدارة.
class LateMatchNotice extends StatelessWidget {
  const LateMatchNotice({super.key, required this.isAdmin, required this.note});

  final bool isAdmin;
  final TextEditingController note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.14),
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          ),
          child: Text(
            isAdmin
                ? 'ديدلاين الجولة دي عدّى — كأدمن تقدر تضيفه عادي، والماتش هيتحسب في الجولة.'
                : 'ديدلاين الجولة دي عدّى (السبت ٣ العصر). هيتبعت طلب للإدارة، '
                      'ولو وافقوا الماتش هيظهر في "ماتشاتي" وتكمّله عادي.',
            style: AppText.body(12, color: AppColors.ink),
          ),
        ),
        if (!isAdmin) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.line, width: 1.2),
            ),
            child: TextField(
              controller: note,
              maxLength: 300,
              maxLines: 3,
              minLines: 2,
              style: AppText.body(13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                hintText: 'ليه اتأخر؟ (اختياري — بيساعد الإدارة توافق)',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
