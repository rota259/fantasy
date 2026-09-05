import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_mark.dart';

/// ترويسة الدخول السوداء: علامة الخماسي + الاسم.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 34, 26, 30),
          child: Row(
            children: [
              const PentagonMark(size: 56, stroke: 5),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الخماسي', style: AppText.h(26, color: AppColors.white)),
                    const SizedBox(height: 3),
                    Text('FANTASY FIVE-A-SIDE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.h(8,
                            color: AppColors.neutral400,
                            weight: FontWeight.w600,
                            spacingEm: 0.28)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
