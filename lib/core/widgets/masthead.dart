import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'motion.dart';

/// ترويسة خضرا موحّدة: زر رجوع اختياري + عنوان + كيكر + عنصر على الجنب.
/// ناعمة: تدرّج خفيف + زوايا مدوّرة من تحت + ظل هادي (بتكمّل شريط الحالة اللي فوقها بنفس اللون).
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.accent, AppColors.accent600],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                  style: AppText.h(18, color: AppColors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h(
                    8,
                    color: AppColors.white,
                    weight: FontWeight.w600,
                    spacingEm: 0.16,
                  ).copyWith(color: AppColors.white.withValues(alpha: 0.75)),
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
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.white),
      ),
    );
  }
}
