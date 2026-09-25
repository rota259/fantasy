import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// ترويسة خضرا موحّدة: زر رجوع اختياري + عنوان + كيكر + عنصر على الجنب.
class Masthead extends StatelessWidget {
  const Masthead({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.trailing,
    this.titleLeading,
  });

  final String title;
  final String subtitle; // الكيكر الإنجليزي
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? titleLeading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          if (onBack != null) ...[_BackButton(onBack!), const SizedBox(width: 12)],
          if (titleLeading != null) ...[titleLeading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h(17, color: AppColors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h(
                    8,
                    color: AppColors.white,
                    weight: FontWeight.w600,
                    spacingEm: 0.16,
                  ).copyWith(color: AppColors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton(this.onTap);
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 2)),
        child: Text('‹', style: AppText.h(16, color: AppColors.white)),
      ),
    );
  }
}
