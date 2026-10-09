import 'package:flutter/material.dart';

import '../../../core/widgets/fx/gold_shine.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/jersey.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../data/models/week_player.dart';

/// أماكن الخماسي: [تحت، شمال فوق، يمين فوق، شمال تحت، يمين تحت] (نفس TeamOfWeek.arrange).
const _spots = [(50.0, 86.0), (29.0, 20.0), (71.0, 20.0), (16.0, 60.0), (84.0, 60.0)];

/// تشكيلة الجولة على الملعب الكلاسيك (فريم نبيتي + نجيلة خضرا) — لاعيبتها بالدهبي عشان مميزين.
class TotwPitch extends StatelessWidget {
  const TotwPitch({super.key, required this.spots, this.contested = false, this.onTap});

  final List<WeekPlayer?> spots; // ٥ أماكن
  final bool contested; // المكان الفاضي عليه تصويت تعادل
  final void Function(WeekPlayer p)? onTap; // الضغط على لاعب = عمل إيه في الجولة

  @override
  Widget build(BuildContext context) {
    return PentagonPitch(
      height: 360,
      framed: true,
      frameColor: PitchColors.forest,
      tokens: [
        for (var i = 0; i < _spots.length && i < spots.length; i++)
          if (spots[i] != null || contested)
            PitchToken(
              leftPct: _spots[i].$1,
              topPct: _spots[i].$2,
              child: spots[i] == null || onTap == null
                  ? _token(spots[i])
                  : Pressable(onTap: () => onTap!(spots[i]!), child: _token(spots[i])),
            ),
      ],
    );
  }

  static const _shadow = [Shadow(color: Color(0x99000000), blurRadius: 4)];

  Widget _token(WeekPlayer? p) => SizedBox(
    width: 80,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (p == null)
          const Jersey(
            label: '⚖️',
            size: 54,
            style: JerseyStyle(
              body: [Color(0x66FFE7A0), Color(0x338C6212)],
              trim: Color(0xFFD9A92B),
              ink: Colors.white,
            ),
          )
        else
          GoldAvatar(player: p, size: 48),
        const SizedBox(height: 3),
        Text(
          p?.name ?? 'تصويت',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.h(10, color: AppColors.white).copyWith(shadows: _shadow),
        ),
        if (p != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: GoldShine(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              delay: (p.id.hashCode % 100) / 100,
              child: Text('${p.points}', style: AppText.h(11, color: const Color(0xFF3A2600))),
            ),
          ),
      ],
    ),
  );
}

/// لاعب الجولة: تيشيرت دهب معدني بيلمع وبيتمايل، والحروف على الصدر.
class GoldAvatar extends StatelessWidget {
  const GoldAvatar({super.key, required this.player, required this.size});
  final WeekPlayer player;
  final double size;

  @override
  Widget build(BuildContext context) => Jersey(
    label: player.initials,
    size: size * 1.12,
    style: JerseyStyle.gold,
    phase: (player.id.hashCode % 100) / 100,
  );
}
