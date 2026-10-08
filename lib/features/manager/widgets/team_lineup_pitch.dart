import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../../players/data/models/player.dart';

/// تشكيلة فريق في ماتش على ملعب خماسي أو سداسي: الحارس تحت والباقي على رؤوس المضلّع،
/// وتحتهم الاحتياطي (اختياري — لحد ما الفريق يكمّل ٧). المكان الفاضي عليه + .
class TeamLineupPitch extends StatelessWidget {
  const TeamLineupPitch({
    super.key,
    required this.team,
    required this.format,
    required this.starters,
    required this.bench,
    required this.onSlot,
    required this.onPlayer,
  });

  final String team;
  final int format; // ٥ أو ٦
  final List<Player> starters;
  final List<Player> bench;
  final void Function(String kind) onSlot; // gk · out · bench
  final void Function(Player p) onPlayer;

  static const squadMax = 7;

  @override
  Widget build(BuildContext context) {
    final shape = format == 6 ? PentagonPitch.hexagon : PentagonPitch.pentagon;
    final gk = starters.where((p) => p.position == 'GK').toList();
    final out = starters.where((p) => p.position != 'GK').toList();
    final benchSlots = squadMax - format;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(team, style: AppText.h(14, color: AppColors.accent)),
            ),
            Text(
              'أساسي ${starters.length}/$format · احتياطي ${bench.length}/$benchSlots',
              style: AppText.body(10, color: AppColors.neutral700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.md,
          child: PentagonPitch(
            height: 250,
            shape: shape,
            tokens: [
              for (var i = 0; i < shape.length; i++)
                PitchToken(
                  leftPct: shape[i].dx * 100,
                  topPct: shape[i].dy * 100,
                  child: i == 0
                      ? _slot(gk.firstOrNull, 'gk', 'حارس')
                      : _slot(i - 1 < out.length ? out[i - 1] : null, 'out', '+'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < benchSlots; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _benchSlot(i < bench.length ? bench[i] : null)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _slot(Player? p, String kind, String hint) {
    if (p == null) {
      return Pressable(
        onTap: () => onSlot(kind),
        child: PentagonIcon(
          size: 42,
          fill: AppColors.night2,
          stroke: AppColors.white.withValues(alpha: 0.5),
          child: Text(hint, style: AppText.h(kind == 'gk' ? 10 : 20, color: AppColors.white)),
        ),
      );
    }
    return Pressable(
      onTap: () => onPlayer(p),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: 42, verified: p.isVerified),
            const SizedBox(height: 2),
            Text(
              '${p.name}${p.position == 'GK' ? ' 🧤' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h(10, color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benchSlot(Player? p) => Pressable(
    onTap: () => p == null ? onSlot('bench') : onPlayer(p),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: p == null ? AppColors.divider : AppColors.line, width: 1.4),
      ),
      child: Text(
        p?.name ?? '+ احتياطي',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.h(11, color: p == null ? AppColors.neutral600 : AppColors.ink),
      ),
    ),
  );
}
