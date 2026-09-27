import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../../../core/widgets/player_token.dart';

/// رسمة الشريحة 1: أرض خماسية بتوكنات أرقام فقط.
class OnboardPitchArt extends StatelessWidget {
  const OnboardPitchArt({super.key});

  @override
  Widget build(BuildContext context) {
    return PentagonPitch(
      height: 230,
      border: AppBorders.solid,
      tokens: const [
        PitchToken(leftPct: 71, topPct: 20, child: PlayerToken(number: '8', isCaptain: true)),
        PitchToken(leftPct: 29, topPct: 20, child: PlayerToken(number: '9')),
        PitchToken(leftPct: 84, topPct: 58, child: PlayerToken(number: '2')),
        PitchToken(leftPct: 16, topPct: 58, child: PlayerToken(number: '5')),
        PitchToken(leftPct: 50, topPct: 84, child: PlayerToken(number: 'GK')),
      ],
    );
  }
}

/// رسمة الشريحة 2: صفوف بث حي.
class OnboardFeedArt extends StatelessWidget {
  const OnboardFeedArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(borderRadius: AppRadius.md, color: AppColors.night2, border: AppBorders.solid),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _row("58'", 'عمر · جوووول ×2', '+7', hot: true),
          _row("44'", 'آدم · جوووول', '+5', hot: true),
          _row("31'", 'حسام · شباك نظيفة', '+4', hot: false),
        ],
      ),
    );
  }

  Widget _row(String min, String who, String pts, {required bool hot}) {
    final c = hot ? AppColors.accent400 : AppColors.white;
    return Opacity(
      opacity: hot ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: const Border(top: BorderSide(color: Color(0x1FFFFFFF))).toBox(),
        child: Row(
          children: [
            Text(min, style: AppText.h(12, color: c)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(who, style: AppText.h(12, color: AppColors.white)),
            ),
            Text(pts, style: AppText.h(15, color: c)),
          ],
        ),
      ),
    );
  }
}

/// رسمة الشريحة 3: لوحة خضرا + كأس.
class OnboardTrophyArt extends StatelessWidget {
  const OnboardTrophyArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(borderRadius: AppRadius.md, color: AppColors.accent, border: AppBorders.solid),
      child: Icon(Icons.emoji_events_outlined, color: AppColors.white, size: 88),
    );
  }
}

extension _BorderToBox on Border {
  BoxDecoration toBox() => BoxDecoration(border: this);
}
