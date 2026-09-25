import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../data/models/week_player.dart';

/// أماكن الخماسي: [تحت، شمال فوق، يمين فوق، شمال تحت، يمين تحت] (نفس TeamOfWeek.arrange).
const _spots = [(50.0, 86.0), (29.0, 20.0), (71.0, 20.0), (16.0, 60.0), (84.0, 60.0)];

/// تشكيلة الجولة على خماسي أزرق (مختلف عن ملعب تشكيلتك الأخضر).
class TotwPitch extends StatelessWidget {
  const TotwPitch({super.key, required this.spots, this.contested = false});

  final List<WeekPlayer?> spots; // ٥ أماكن
  final bool contested; // المكان الفاضي عليه تصويت تعادل

  @override
  Widget build(BuildContext context) {
    return PentagonPitch(
      height: 340,
      background: AppColors.navy,
      stripe: AppColors.navyStripe,
      line: AppColors.navyLine,
      tokens: [
        for (var i = 0; i < _spots.length && i < spots.length; i++)
          if (spots[i] != null || contested)
            PitchToken(leftPct: _spots[i].$1, topPct: _spots[i].$2, child: _token(spots[i])),
      ],
    );
  }

  Widget _token(WeekPlayer? p) => SizedBox(
    width: 80,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (p == null)
          const PentagonIcon(
            size: 48,
            fill: AppColors.navyStripe,
            stroke: AppColors.info,
            child: Text('⚖️', style: TextStyle(fontSize: 18)),
          )
        else
          PentagonAvatar(
            initials: p.initials,
            photoUrl: p.imageUrl,
            size: 48,
            background: AppColors.info,
            verified: p.verified,
          ),
        const SizedBox(height: 3),
        Text(
          p?.name ?? 'تصويت',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.h(10, color: AppColors.white),
        ),
        if (p != null)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            color: AppColors.white,
            child: Text('${p.points}', style: AppText.h(11, color: AppColors.navy)),
          ),
      ],
    ),
  );
}
