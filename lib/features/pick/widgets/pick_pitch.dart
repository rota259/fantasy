import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/jersey.dart';
import '../../../core/widgets/photo_card.dart';
import '../../../core/widgets/formation_pitch.dart';
import '../../players/data/models/player.dart';
import '../cubit/round_pick_cubit.dart';
import '../../../core/widgets/fx/effects.dart';
import '../../../core/widgets/fx/flips.dart';
import '../../../core/widgets/motion.dart';
import 'points_pop.dart';

part 'pick_pitch_sections.dart';
part 'pick_pitch_sections2.dart';

/// ملعب خماسي: ٥ نقاط للأساسيين (حارس + ٤ من أي فرق) + ٢ احتياطي تحت.
/// النقطة الفاضية عليها علامة +، والمليانة عليها اللاعب وشارة C/V.
class PickPitch extends StatelessWidget {
  const PickPitch({
    super.key,
    required this.state,
    required this.onSlotTap,
    required this.onPlayerTap,
    this.pointsFor,
    this.liveTeams = const {},
    this.onSwap,
    this.onMoveTo,
    this.entryKey,
  });

  final RoundPickState state;
  final void Function(String kind) onSlotTap; // gk · out · bench
  final void Function(Player p) onPlayerTap;

  /// لو متحدّد: بيظهر جنب كل لاعب نقطه (للعرض — شاشة تفاصيل النقط).
  final Map<String, int>? pointsFor;

  /// الفرق اللي بتلعب ماتش دلوقتي — لاعيبتها بتنبض بلون مختلف وقت الماتش بس.
  final Set<String> liveTeams;

  /// السحب والإفلات (لو التعديل مسموح): لاعب على لاعب = تبديل · لاعب على مكان فاضي = ينتقل له.
  final void Function(String fromId, String toId)? onSwap;
  final void Function(String fromId, String kind)? onMoveTo;

  /// بيتغيّر بعد الحفظ → اللاعيبة يدخلوا الملعب واحد ورا التاني.
  final int? entryKey;

  bool get _draggable => onSwap != null;

  @override
  Widget build(BuildContext context) => _buildBody(context);

  Widget _plus(VoidCallback onTap) => Pressable(
    onTap: onTap,
    // مكان فاضي: تيشيرت شفاف عليه +
    child: const Jersey(label: '+', style: _ghost, size: 50),
  );

  static const _ghost = JerseyStyle(
    body: [Color(0x55FFFFFF), Color(0x26FFFFFF)],
    trim: Color(0x99FFFFFF),
    ink: Colors.white,
    shine: 0,
  );

  /// اللاعب على الملعب: صورته في إطار كارت لو ليه صورة (أبيض · الحارس فحمي · الكابتن دهب بيلمع)،
  /// ولو مالوش → تيشيرت بنفس الألوان.
  static Widget _shirt(Player p, bool captain, [double size = 52]) {
    final jersey = Jersey(
      label: p.initials,
      size: size,
      style: captain ? JerseyStyle.gold : (p.position == 'GK' ? JerseyStyle.keeper : JerseyStyle.white),
      phase: (p.id.hashCode % 100) / 100,
    );
    final url = p.imageUrl;
    if (url == null || url.isEmpty) return jersey;
    // صورة اللاعب في إطار كارت (مش دايرة): أبيض · الحارس فحمي · الكابتن دهب بيلمع
    return PhotoCard(
      url: url,
      width: size * 0.92,
      fallback: jersey,
      gold: captain,
      frame: p.position == 'GK' ? const Color(0xFF2B2B2B) : Colors.white,
      phase: (p.id.hashCode % 100) / 100,
    );
  }

  /// الاحتياطي وهو بيتسحب.
  static Widget _avatar(Player p, double size) => _shirt(p, false, size);
}
