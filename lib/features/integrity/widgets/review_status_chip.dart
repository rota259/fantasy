import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/data/models/game_match.dart';

/// حالة اعتماد الماتش: مبدئي ⏳ · معتمد ✓ · اعتراض ⚠️ · اتلغى 🚫 (ولا حاجة لو لسه مخلصش).
class ReviewStatusChip extends StatelessWidget {
  const ReviewStatusChip({super.key, required this.match});

  final GameMatch match;

  static (String, Color)? of(GameMatch m) {
    if (!m.isFinished) return null;
    return switch (m.reviewStatus) {
      'pending' => ('مبدئي ⏳', AppColors.bronze),
      'disputed' => ('اعتراض ⚠️', AppColors.danger),
      'void' => ('اتلغى 🚫', AppColors.neutral600),
      'approved' => ('معتمد ✓', AppColors.accent),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = of(match);
    if (s == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: s.$2,
      child: Text(s.$1, style: AppText.h(10, color: AppColors.white)),
    );
  }
}
