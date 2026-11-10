part of 'manager_hub_screen.dart';

extension _ManagerHubScreenSections2 on ManagerHubScreen {
  Widget _buildBody(BuildContext context) {
    final players = context.read<PlayersRepository>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'لوحة الأدمن', subtitle: 'ADMIN', onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const ManagerDashboard(),
                ..._matchTiles(context, players),
                ..._communityTiles(context, players),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// النزاهة + الماتشات واللاعيبة.
  List<Widget> _matchTiles(BuildContext context, PlayersRepository players) => [
    _group('النزاهة'),
    _tile(
      context,
      Icons.gavel_outlined,
      'مراجعة الماتشات',
      'اعتراضات اللاعيبة + الماتشات المعلّم عليها — احكم',
      const AdminReviewScreen(),
    ),
    _tile(
      context,
      Icons.how_to_reg_outlined,
      'طلبات المديرين',
      'مين عايز ينظّم ماتشات — وافق أو ارفض',
      const AdminOrganizersScreen(),
    ),
    _tile(
      context,
      Icons.block_outlined,
      'بلاغات المراهنات',
      'حقّق في البلاغات — اللي يتثبت عليه بان نهائي',
      const AdminBettingScreen(),
    ),
    _tile(context, Icons.history, 'سجل العمليات', 'مين من الأدمنز عمل إيه وإمتى', const AdminLogScreen()),
    _tile(
      context,
      Icons.monitor_heart_outlined,
      'السجلات والأخطاء',
      'إيه اللي باظ · إمتى · عند مين — وابحث برقم الطلب',
      const AdminLogsScreen(),
    ),
    _group('الماتشات واللاعيبة'),
    _tile(
      context,
      Icons.event_note_outlined,
      'إدارة الماتشات',
      'تشكيلات · أحداث · نتيجة · مين نزّل',
      ManagerMatchesScreen(
        matchesRepo: context.read<MatchesRepository>(),
        playersRepo: players,
        eventsRepo: context.read<EventsRepository>(),
        lineupRepo: context.read<LineupRepository>(),
      ),
    ),
    _tile(
      context,
      Icons.shield_outlined,
      'الفرق',
      'كل الفرق بمناطقها وأصحابها — حدّد منطقة الفرق القديمة',
      const AdminTeamsScreen(),
    ),
    _tile(
      context,
      Icons.groups_outlined,
      'إدارة اللاعيبة',
      'ضيف وعدّل واحذف',
      ManagerPlayersScreen(playersRepo: players),
    ),
    _tile(
      context,
      Icons.healing_outlined,
      'حالة اللاعيبة',
      'جاهز / مصاب / موقوف + السبب',
      ManagerAvailabilityScreen(playersRepo: players),
    ),
    _tile(
      context,
      Icons.verified_outlined,
      'توثيق اللاعيبة',
      'طلبات "ده أنا" — وافق أو ارفض',
      const ManagerClaimsScreen(),
    ),
  ];
}
