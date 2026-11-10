import 'package:flutter/material.dart';

import '../../../core/share/story_parts.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';

/// ألوان سلايد من «جولتك في ٥ سلايدز» — كل سلايد بلون عشان التقليب يبان.
class WrappedTone {
  const WrappedTone(this.colors, this.fg, this.accent);
  final List<Color> colors;
  final Color fg; // الكلام
  final Color accent; // الرقم/الاسم الكبير والكبسولات

  static const forest = WrappedTone([StoryColors.forest, StoryColors.deep], Colors.white, StoryColors.lime);
  static const lime = WrappedTone([StoryColors.lime, Color(0xFFA6DB3A)], StoryColors.ink, StoryColors.forest);
  static const ink = WrappedTone([StoryColors.ink, Color(0xFF050B09)], Colors.white, StoryColors.gold);
  static const grass = WrappedTone([StoryColors.grass, StoryColors.forest], Colors.white, StoryColors.lime);
  static const share = WrappedTone([StoryColors.deep, Color(0xFF020F0B)], Colors.white, StoryColors.lime);

  static const all = [forest, lime, ink, grass, share];
}

/// سلايد واحد: رقم السلايد باهت كبير · كبسولة العنوان · القيمة الكبيرة (بتدخل بنطّة) · سطر تحتها · تعليق.
class WrappedSlide extends StatelessWidget {
  const WrappedSlide({
    super.key,
    required this.tone,
    required this.index,
    required this.title,
    required this.value,
    required this.sub,
    this.extra,
    this.extraIcon,
  });

  final WrappedTone tone;
  final int index; // ١..٤
  final String title, sub;
  final Widget value;
  final String? extra;
  final IconData? extraIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('0$index', style: AppText.h(72, color: tone.fg.withValues(alpha: 0.12), height: 1)),
          const SizedBox(height: 6),
          StoryPill(title, color: tone.accent, onColor: tone.colors.first, filled: true, size: 14),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: Duration(milliseconds: Motion.reduced(context) ? 1 : 700),
            curve: Curves.easeOutBack,
            builder: (_, s, c) => Transform.scale(scale: s, alignment: AlignmentDirectional.centerStart, child: c),
            child: value,
          ),
          const SizedBox(height: 10),
          Text(sub, style: AppText.h(22, color: tone.fg)),
          if (extra != null) ...[
            const SizedBox(height: 22),
            FadeSlideIn(
              index: 6,
              child: StoryPill(extra!, icon: extraIcon, color: tone.fg, size: 14),
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
