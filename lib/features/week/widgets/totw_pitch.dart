import 'package:flutter/material.dart';

import '../../../core/widgets/fx/gold_shine.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/jersey.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/formation_pitch.dart';
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
    return FormationPitch(
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

/// لاعب الجولة: لو ليه صورة على الأبلكيشن بتظهر صورته جوه فريم دهب معدني بيلمع،
/// ولو مالوش → تيشيرت دهب عليه حروفه. [card] = مقاس كارت فيفا (مستطيل بدل الدايرة).
class GoldAvatar extends StatelessWidget {
  const GoldAvatar({super.key, required this.player, required this.size, this.card = false});
  final WeekPlayer player;
  final double size;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final phase = (player.id.hashCode % 100) / 100;
    final jersey = Jersey(label: player.initials, size: size * 1.12, style: JerseyStyle.gold, phase: phase);
    final url = player.imageUrl;
    if (url == null || url.isEmpty) return jersey;
    final ring = (size * 0.07).clamp(2.5, 6.0);
    final w = size, h = card ? size * 1.2 : size;
    final radius = BorderRadius.circular(card ? size * 0.16 : size);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      // الفريم الدهب بيلمع، والصورة جواه (ولو الصورة ماحمّلتش → الحروف على الدهب)
      child: GoldShine(
        shape: RoundedRectangleBorder(borderRadius: radius),
        padding: EdgeInsets.all(ring),
        delay: phase,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(card ? size * 0.12 : size),
          child: NetImage(
            url,
            width: w - ring * 2,
            height: h - ring * 2,
            fallback: SizedBox(
              width: w - ring * 2,
              height: h - ring * 2,
              child: Center(
                child: Text(player.initials, style: AppText.h(size * 0.3, color: const Color(0xFF3A2600))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
