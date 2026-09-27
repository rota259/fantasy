import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../../polls/data/models/poll.dart';
import '../data/video_link.dart';
import 'pitch_backdrop.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/motion.dart';

/// مرشّح هدف/تصدّي: الفيديو (دوس في أي حتة في المربع يفتح) + الاسم + الأصوات
/// + زرار تصويت تحته بيقلب أخضر لما تصوّت.
class AwardOptionCard extends StatelessWidget {
  const AwardOptionCard({
    super.key,
    required this.option,
    required this.total,
    required this.showResults,
    required this.winner,
    this.onVote,
  });

  final PollOption option;
  final int total;
  final bool showResults;
  final bool winner;
  final VoidCallback? onVote; // null = التصويت مقفول

  Future<void> _play(BuildContext context) async {
    final url = option.videoUrl;
    if (url == null) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await Launchers.url(url)) {
      messenger.showSnackBar(const SnackBar(content: Text('مقدرتش أفتح الفيديو')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = option.videoUrl == null ? null : VideoLink.thumbnail(option.videoUrl!);
    final pct = total == 0 ? 0.0 : option.votes / total;
    final voted = option.mine;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: voted || winner ? AppColors.accent : AppColors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            behavior: HitTestBehavior.opaque,
            onTap: () => _play(context),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumb != null) NetImage(thumb, fallback: const PitchBackdrop()) else const PitchBackdrop(),
                  Container(color: AppColors.black.withValues(alpha: 0.15)),
                  Center(child: Icon(Icons.play_circle_fill, size: 58, color: AppColors.white)),
                  if (winner)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.gold, borderRadius: AppRadius.sm),
                        child: Text('🏆 الفايز', style: AppText.h(11, color: AppColors.black)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(child: Text(option.label, style: AppText.h(14))),
                if (showResults) Text('${(pct * 100).round()}% · ${option.votes} صوت', style: AppText.h(12)),
              ],
            ),
          ),
          if (showResults)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1).toDouble(),
                minHeight: 6,
                color: AppColors.accent,
                backgroundColor: AppColors.neutral200,
              ),
            ),
          if (onVote != null)
            Pressable(
              onTap: voted ? null : onVote,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                color: voted ? AppColors.accent : AppColors.black,
                child: Text(voted ? '✓ صوتك هنا' : 'صوّت', style: AppText.h(14, color: AppColors.white)),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}
