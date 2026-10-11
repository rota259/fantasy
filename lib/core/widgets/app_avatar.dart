import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'net_image.dart';

/// صورة جوه دايرة — ولو مفيش صورة أول حرفين من الاسم.
/// بتستخدم لليوزرز واللاعيبة في كل التطبيق.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.size = 46,
    this.background,
    this.color,
    this.verified = false,
  });

  final String initials;
  final String? photoUrl;
  final double size;
  final Color? background; // الافتراضي accent
  final Color? color; // الافتراضي white

  /// علامة ✓ صغيرة (لاعب موثّق).
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final fallback = Center(
      child: Text(initials, style: AppText.h(size * 0.32, color: color ?? AppColors.white)),
    );
    final shape = SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: ColoredBox(
          color: background ?? AppColors.accent,
          child: (url == null || url.isEmpty) ? fallback : NetImage(url, width: size, height: size, fallback: fallback),
        ),
      ),
    );
    if (!verified) return shape;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        shape,
        Positioned(
          bottom: -1,
          right: -1,
          child: Container(
            width: size * 0.34,
            height: size * 0.34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.card, width: 1.5),
            ),
            child: Icon(Icons.check, size: size * 0.2, color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

/// مربع ناعم بحواف مدوّرة فيه أيقونة (المختصرات والشارات والكروت).
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.child, this.size = 56, this.fill, this.stroke, this.strokeWidth = 1.4});

  final Widget child;
  final double size;
  final Color? fill; // الافتراضي card
  final Color? stroke; // الافتراضي line
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill ?? AppColors.card,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: strokeWidth <= 0 ? null : Border.all(color: stroke ?? AppColors.line, width: strokeWidth),
      ),
      child: child,
    );
  }
}
