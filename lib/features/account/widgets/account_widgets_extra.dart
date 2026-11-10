part of 'account_widgets.dart';

/// أرقامي: إجمالي النقاط (الضغط → تفاصيل كل جولة وموسم) + الترتيب العام + أحسن جولة.
class AccountStats extends StatelessWidget {
  const AccountStats({super.key, this.user, this.rank = 0, this.bestMatch = 0, this.onPointsTap});
  final AppUser? user;
  final int rank;
  final int bestMatch;
  final VoidCallback? onPointsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: Row(
        children: [
          _stat(
            user != null ? '${user!.totalPoints}' : '—',
            onPointsTap == null ? 'إجمالي النقاط' : 'إجمالي النقاط · التفاصيل ›',
            border: true,
            color: onPointsTap == null ? null : AppColors.accent,
            onTap: onPointsTap,
          ),
          _stat(rank > 0 ? '$rank' : '—', 'الترتيب العام', border: true),
          _stat(bestMatch > 0 ? '$bestMatch' : '—', 'أحسن جولة', color: AppColors.accent),
        ],
      ),
    );
  }

  Widget _stat(String v, String k, {bool border = false, Color? color, VoidCallback? onTap}) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: border ? Border(left: BorderSide(color: AppColors.divider)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v, style: AppText.h(22, color: color ?? AppColors.ink)),
              Text(k, style: AppText.body(9, color: AppColors.neutral700)),
            ],
          ),
        ),
      ),
    );
  }
}
