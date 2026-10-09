import 'package:flutter/material.dart';

import '../../../core/widgets/jersey.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../../matches/widgets/match_format.dart';
import '../../polls/data/models/poll.dart';
import '../data/models/week_player.dart';
import '../../../core/widgets/motion.dart';

/// تعادل على آخر مكان في تشكيلة الجولة: المتعادلين + التصويت (أو النتيجة).
class TotwTieSection extends StatelessWidget {
  const TotwTieSection({super.key, required this.tied, required this.slots, required this.poll, required this.onVote});

  final List<WeekPlayer> tied;
  final int slots;
  final PollView? poll; // null = السيرفر لسه ماعملش التصويت
  final ValueChanged<String> onVote; // optionId

  @override
  Widget build(BuildContext context) {
    final v = poll;
    final open = v?.poll.open ?? false;
    final closes = v?.poll.closesAt;
    final header = v == null
        ? 'تعادل على ${slots == 1 ? 'آخر مكان' : 'آخر $slots أماكن'} — التصويت هيبدأ بعد ما الجولة تقفل'
        : open
        ? 'تعادل! صوّت مين يدخل التشكيلة${closes != null ? ' — لحد ${arabicTime(closes)}' : ''}'
        : 'التصويت خلص${v.winners.isEmpty ? ' من غير أصوات' : ' — دخل: ${v.winners.map((o) => o.label).join('، ')}'}';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: PitchColors.forest, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(color: PitchColors.forest, borderRadius: AppRadius.md),
            padding: const EdgeInsets.all(10),
            child: Text('⚖️ $header', style: AppText.h(12, color: AppColors.white)),
          ),
          for (final p in tied) _row(p, v, open),
        ],
      ),
    );
  }

  Widget _row(WeekPlayer p, PollView? v, bool open) {
    PollOption? opt;
    for (final o in v?.options ?? const <PollOption>[]) {
      if (o.playerId == p.id) opt = o;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.55))),
      ),
      child: Row(
        children: [
          Jersey(label: p.initials, size: 32),
          const SizedBox(width: 10),
          Expanded(child: Text('${p.name} · ${p.points} نقطة', style: AppText.h(13))),
          if (opt != null && (v!.iVoted || !open)) Text('${opt.votes} صوت  ', style: AppText.h(11)),
          if (opt != null && open)
            Pressable(
              onTap: () => onVote(opt!.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: opt.mine ? const Color(0xFFC9971C) : PitchColors.grass,
                  borderRadius: AppRadius.md,
                ),
                child: Text(opt.mine ? 'صوتك ✓' : 'صوّت', style: AppText.h(11, color: AppColors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
