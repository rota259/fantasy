part of 'manager_dashboard.dart';

extension _ManagerDashboardStateSections1 on _ManagerDashboardState {
  Future<_Stats> _load() async {
    final admin = context.read<AdminRepository>();
    final (counts, top, picks, betting) = await (
      admin.counts(),
      admin.fetchUsers(role: 'user', limit: 5),
      admin.roundPickerCount(WeekWindow.open().cutoff),
      // بلاغات المراهنات اللي لسه مفتوحة
      context
          .read<FairPlayRepository>()
          .adminReports()
          .then((l) => l.where((r) => r.status == 'open' || r.status == 'investigating').length)
          .catchError((_) => 0),
    ).wait;
    return (counts: counts, top: top, nextPicks: picks, managersActive: counts.managers, betting: betting);
  }

  /// كارت رقم: أيقونة + الرقم + الاسم — بيتضغط.
  Widget _stat(BuildContext context, int value, String label, IconData icon, Widget screen) => Pressable(
    onTap: () => _open(context, screen),
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: AppDecor.tile,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.accent100, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUp(value: value, style: AppText.h(22, height: 1)),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, size: 18, color: AppColors.neutral500),
        ],
      ),
    ),
  );
}
