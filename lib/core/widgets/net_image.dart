import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// صورة من النت بتتخزّن على الموبايل (مش بتتحمّل تاني كل مرة) + بديل لو فشلت.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height, this.fallback});

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final alt = fallback ?? Container(width: width, height: height, color: AppColors.neutral200);
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      // نحمّل الصورة بحجم العرض بس (مش الأصلي) — أسرع وأقل ذاكرة
      memCacheWidth: width == null ? null : (width! * MediaQuery.devicePixelRatioOf(context)).round(),
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) => Container(width: width, height: height, color: AppColors.neutral200),
      errorWidget: (_, __, ___) => alt,
    );
  }
}
