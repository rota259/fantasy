part of 'venue_stats_section.dart';

extension _VenueStatsParts on _VenueStatsSectionState {
  Widget _num(String v, String label) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: AppDecor.tile,
      child: Column(
        children: [
          Text(v, style: AppText.h(18)),
          Text(label, style: AppText.body(10, color: AppColors.neutral700)),
        ],
      ),
    ),
  );

  String _initials(String n) => n.trim().length >= 2 ? n.trim().substring(0, 2) : '؟';

  /// أسطورة الملعب: أكتر لاعب أهداف + أسيستات في ماتشات الملعب.
  Widget _legend(VenueStar p) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.night, AppColors.night2]),
      borderRadius: BorderRadius.circular(AppRadius.m),
      border: Border.all(color: AppColors.gold, width: 1.5),
    ),
    child: Row(
      children: [
        AppAvatar(initials: _initials(p.name), photoUrl: p.imageUrl, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👑 أسطورة الملعب', style: AppText.h(11, color: AppColors.gold)),
              Text(p.label, style: AppText.h(17, color: AppColors.white)),
              Text(
                '${p.team} · ${p.goals} جول · ${p.assists} أسيست في ${p.matches} ماتش',
                style: AppText.body(11, color: AppColors.neutral300),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _scorer(int rank, VenueStar p) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: AppDecor.softDivider,
    child: Row(
      children: [
        SizedBox(
          width: 22,
          child: Text('$rank', style: AppText.h(13, color: AppColors.neutral600)),
        ),
        Expanded(child: Text('${p.label} · ${p.team}', style: AppText.body(12))),
        Text('${p.goals} ⚽  ${p.assists} 🎯', style: AppText.h(12)),
      ],
    ),
  );

  /// (صاحب الملعب) الماتشات بالساعة آخر ٩٠ يوم — عشان يعرف الساعات الفاضية.
  Widget _hours(Map<int, int> hours) {
    if (hours.isEmpty) {
      return Text(
        'أول ما الماتشات تتلعب عندك هتشوف هنا أكتر الساعات زحمة والساعات الفاضية.',
        style: AppText.body(11, color: AppColors.neutral700),
      );
    }
    final keys = hours.keys.toList()..sort();
    final max = hours.values.reduce((a, b) => a > b ? a : b);
    String h(int x) => x == 0 ? '١٢ص' : (x < 12 ? '$xص' : (x == 12 ? '١٢م' : '${x - 12}م'));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('📊 لوحتك: الماتشات بالساعة (آخر ٩٠ يوم)', style: AppText.h(12)),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final k in keys)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${hours[k]}', style: AppText.body(9)),
                        Container(
                          height: 56 * hours[k]! / max,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: hours[k] == max ? AppColors.accent : AppColors.accent300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(h(k), style: AppText.body(9, color: AppColors.neutral700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'الساعات اللي مش ظاهرة فاضية — اعمل فيها بطولة أو عرض وأعلن عنه لأهل المنطقة.',
            style: AppText.body(10, color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }
}
