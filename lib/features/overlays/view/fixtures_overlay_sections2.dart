part of 'fixtures_overlay.dart';

extension _FixturesViewSections2 on _FixturesView {
  /// ماتش خلص: النتيجة + تقييم الجمهور (مفتوح ٢٤ ساعة) أو نتيجة التقييم.
  Widget _result(BuildContext context, GameMatch m) {
    final uid = userId;
    final canRate = m.ratingOpen;
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: () => MatchCenterScreen.open(context, m),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppDecor.tile,
        child: Row(
          children: [
            Expanded(
              child: Text(m.teamA, textAlign: TextAlign.end, style: AppText.h(13)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
              child: Text(m.scoreText.isEmpty ? '—' : m.scoreText, style: AppText.h(14, color: AppColors.white)),
            ),
            Expanded(child: Text(m.teamB, style: AppText.h(13))),
            if (uid != null && (canRate || m.motmDone))
              Pressable(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchRatingsScreen(match: m, userId: uid),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  color: canRate ? AppColors.accent : null,
                  decoration: canRate
                      ? null
                      : BoxDecoration(
                          borderRadius: AppRadius.md,
                          border: Border.all(color: AppColors.line, width: 1.2),
                        ),
                  child: Text(
                    canRate ? 'قيّم' : 'رجل الماتش',
                    style: AppText.h(10, color: canRate ? AppColors.white : AppColors.ink),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          Text(
            'FDR: ',
            style: AppText.body(10, color: AppColors.neutral700, weight: FontWeight.w600),
          ),
          const FdrChip(2, size: 20),
          Text(' سهل   ', style: AppText.body(10, color: AppColors.neutral700)),
          const FdrChip(5, size: 20),
          Text(' صعب', style: AppText.body(10, color: AppColors.neutral700)),
        ],
      ),
    );
  }
}
