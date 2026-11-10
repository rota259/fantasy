part of 'manager_hub_screen.dart';

extension _ManagerHubScreenSections3 on ManagerHubScreen {
  /// المسابقات + المجتمع.
  List<Widget> _communityTiles(BuildContext context, PlayersRepository players) => [
    _group('المسابقات'),
    _tile(
      context,
      Icons.star_border,
      'تشكيلات الجولة',
      'اعتمد تشكيلة كل منطقة عشان تنزل لأهلها',
      const AdminTotwScreen(),
    ),
    _tile(
      context,
      Icons.sports_score_outlined,
      'تحدّي الجولة',
      'أي ماتش (المديرين بيختاروا من ماتشاتهم) — فرق الأهداف الصح +٥',
      const ManagerChallengeScreen(),
    ),
    _tile(
      context,
      Icons.play_circle_outline,
      'هدف وتصدّي الجولة',
      'مرشّحين بفيديو + نتايج + تصويت السنة',
      const ManagerAwardsScreen(),
    ),
    _group('المجتمع'),
    _tile(
      context,
      Icons.system_update_alt_rounded,
      'التحديث الإجباري',
      'حدّد أقل نسخة مسموحة — الأقدم مبيفتحش غير لما يحدّث',
      const AdminUpdateScreen(),
    ),
    _tile(
      context,
      Icons.notifications_active_outlined,
      'فحص الإشعارات',
      'ليه الإشعار مبيوصلش والأبلكيشن مقفول؟ + إشعار تجربة',
      const PushCheckScreen(),
    ),
    _tile(context, Icons.campaign_outlined, 'إشعار للكل', 'ابعت أي رسالة لكل اليوزرز', const ManagerBroadcastScreen()),
    _tile(
      context,
      Icons.leaderboard_outlined,
      'الدوريات',
      'كل دوريات اليوزرز — احذف المخالف',
      const ManagerLeaguesScreen(),
    ),
    _tile(
      context,
      Icons.manage_accounts_outlined,
      'المستخدمين',
      'مديرين المناطق + نقل حد لمنطقة تانية',
      const ManagerUsersScreen(),
    ),
    _tile(
      context,
      Icons.location_on_outlined,
      'الملاعب',
      'كل الملاعب (بتاعتك وبتاعة اليوزرز) + صاحبها',
      const ManagerVenuesScreen(),
    ),
    _tile(
      context,
      Icons.event_available_outlined,
      'طلبات الحجز',
      'كل الحجوزات — أكّد أو ارفض',
      const VenueRequestsScreen(),
    ),
  ];
}
