import 'package:flutter/material.dart';

import '../theme/app_text.dart';

/// إطار كارت الشير بمقاس Instagram story (٩:١٦): خلفية متدرّجة + اسم الأبلكيشن فوق + كود الدعوة تحت.
/// بيتحط جوه RepaintBoundary وبيتشيّر صورة بـ ShareCard.share.
class StoryFrame extends StatelessWidget {
  const StoryFrame({
    super.key,
    required this.child,
    this.kicker,
    this.refCode,
    this.colors = const [Color(0xFF0C3B22), Color(0xFF111914)],
  });

  final Widget child;
  final String? kicker; // سطر صغير تحت اسم الأبلكيشن (المنطقة · الجولة)
  final String? refCode;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          children: [
            Text('الخماسي ⚽', style: AppText.h(24, color: Colors.white)),
            if (kicker != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(kicker!, style: AppText.body(12, color: Colors.white.withValues(alpha: 0.7))),
              ),
            Expanded(child: Center(child: child)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text('فانتازي ماتشات الخماسي في منطقتك', style: AppText.h(12, color: Colors.white)),
                  if (refCode != null)
                    Text('كود الدعوة: $refCode', style: AppText.h(13, color: const Color(0xFFF2C14E))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final gold = const Color(0xFFF2C14E);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?photo,
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.h(star ? 15 : 12, color: star ? gold : Colors.white),
        ),
        Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: star ? gold : Colors.white24, borderRadius: BorderRadius.circular(8)),
          child: Text('$points', style: AppText.h(12, color: star ? Colors.black : Colors.white)),
        ),
      ],
    );
  }
}
