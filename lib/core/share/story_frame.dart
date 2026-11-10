import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../widgets/brand_logo.dart';
import '../widgets/fx/gold_shine.dart';
import 'story_parts.dart';

export 'story_parts.dart';

/// إطار كارت الشير بمقاس Instagram story (٩:١٦): ملعب غامق بخطوطه + اللوجو والجولة فوق + تذكرة الدعوة تحت.
/// الكارت مرسوم على لوحة ثابتة ٣٦٠×٦٤٠ وبتتكبّر/تتصغّر كلها — فشكله واحد على أي موبايل ومفيش كلام بيتقص.
/// بيتحط جوه RepaintBoundary وبيتشيّر صورة بـ ShareCard.share (الحواف المدوّرة بتتعمل برّه في المعاينة).
class StoryFrame extends StatelessWidget {
  const StoryFrame({
    super.key,
    required this.child,
    this.kicker,
    this.refCode,
    this.colors = const [StoryColors.forest, StoryColors.deep],
  });

  final Widget child;
  final String? kicker; // كبسولة فوق (المنطقة · الجولة)
  final String? refCode;
  final List<Color> colors;

  static const _w = 360.0, _h = 640.0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: FittedBox(
        child: SizedBox(
          width: _w,
          height: _h,
          child: StoryBackdrop(
            colors: colors,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BrandLockup(height: 30, onDark: true),
                      const SizedBox(width: 10),
                      if (kicker != null)
                        Expanded(
                          child: Align(alignment: AlignmentDirectional.centerEnd, child: StoryPill(kicker!)),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(width: _w - 48, child: child),
                      ),
                    ),
                  ),
                  _ticket(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// تذكرة الدعوة: شريط فسفوري وعليه الكود في خانة غامقة.
  Widget _ticket() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
    decoration: BoxDecoration(color: StoryColors.lime, borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                refCode == null ? 'نزّل الخماسي والعب' : 'العب معايا ',
                style: AppText.h(14, color: StoryColors.ink),
              ),
              const SizedBox(height: 2),
              Text(
                'فانتازي الخماسي ',
                style: AppText.body(10, color: StoryColors.ink.withValues(alpha: 0.72), height: 1.2),
              ),
            ],
          ),
        ),
        if (refCode != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: StoryColors.ink, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text('كود الدعوة', style: AppText.kicker(color: StoryColors.lime, size: 8)),
                Text(refCode!, style: AppText.h(16, color: Colors.white, spacingEm: 0.08)),
              ],
            ),
          ),
      ],
    ),
  );
}

/// كارت لاعب صغير (للشير وللكشف): صورة + اسم + نقط.
class StoryPlayer extends StatelessWidget {
  const StoryPlayer({super.key, required this.name, required this.points, this.photo, this.star = false});
  final String name;
  final int points;
  final Widget? photo;
  final bool star;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFE7A0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?photo,
        const SizedBox(height: 5),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.h(star ? 20 : 11, color: star ? gold : Colors.white),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: EdgeInsets.symmetric(horizontal: star ? 14 : 8, vertical: 2),
          decoration: BoxDecoration(
            color: star ? null : Colors.white.withValues(alpha: 0.16),
            gradient: star ? GoldShine.gradient : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$points',
            style: AppText.h(star ? 20 : 12, color: star ? const Color(0xFF3A2600) : Colors.white),
          ),
        ),
      ],
    );
  }
}
