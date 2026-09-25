import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'net_image.dart';

/// الشكل الخماسي بتاع الهوية (رأسه لفوق).
const ShapeBorder kPentagon = StarBorder.polygon(sides: 5);

/// صورة جوه خماسي — ولو مفيش صورة أول حرفين من الاسم.
/// بتستخدم لليوزرز واللاعيبة في كل التطبيق.
class PentagonAvatar extends StatelessWidget {
  const PentagonAvatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.size = 46,
    this.background = AppColors.accent,
    this.color = AppColors.white,
    this.verified = false,
  });

  final String initials;
  final String? photoUrl;
  final double size;
  final Color background;
  final Color color;

  /// علامة ✓ صغيرة (لاعب موثّق).
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final fallback = Center(
      child: Padding(
        padding: EdgeInsets.only(top: size * 0.12),
        child: Text(initials, style: AppText.h(size * 0.3, color: color)),
      ),
    );
    final shape = SizedBox(
      width: size,
      height: size,
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: kPentagon),
        child: ColoredBox(
          color: background,
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
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.34,
            height: size * 0.34,
            alignment: Alignment.center,
            decoration: const ShapeDecoration(color: AppColors.info, shape: CircleBorder()),
            child: Icon(Icons.check, size: size * 0.24, color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

/// كارت/زرار على شكل خماسي فيه أيقونة (المختصرات والشارات).
class PentagonIcon extends StatelessWidget {
  const PentagonIcon({
    super.key,
    required this.child,
    this.size = 56,
    this.fill = AppColors.white,
    this.stroke = AppColors.black,
    this.strokeWidth = 2,
  });

  final Widget child;
  final double size;
  final Color fill;
  final Color stroke;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.only(top: size * 0.1),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: fill,
        shape: StarBorder.polygon(
          sides: 5,
          side: strokeWidth <= 0 ? BorderSide.none : BorderSide(color: stroke, width: strokeWidth),
        ),
      ),
      child: child,
    );
  }
}
