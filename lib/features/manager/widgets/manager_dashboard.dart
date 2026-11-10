import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/data/models/app_user.dart';
import '../../week/data/week_window.dart';
import '../data/admin_repository.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/motion.dart';
import '../../events/data/events_repository.dart';
import '../../fairplay/data/fairplay_repository.dart';
import '../../fairplay/view/admin_betting_screen.dart';
import '../../matches/data/matches_repository.dart';
import '../../players/data/players_repository.dart';
import '../../points/view/live_round_screen.dart';
import '../data/lineup_repository.dart';
import '../view/manager_matches_screen.dart';
import '../view/manager_players_screen.dart';
import '../view/manager_users_screen.dart';

part 'manager_dashboard_sections.dart';
part 'manager_dashboard_sections2.dart';

typedef _Stats = ({AdminCounts counts, List<AppUser> top, int nextPicks, int managersActive, int betting});

/// (أدمن) أرقام سريعة من السيرفر — كل رقم كارت بيفتح القايمة بتاعته (من غير ما نحمّل كل اليوزرز واللاعيبة): المستخدمين، اللاعيبة، الماتشات،
/// تشكيلات الجولة الجاية، وأعلى ٥.
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  late final Future<_Stats> _future = _load();

  @override
  Widget build(BuildContext context) => _buildBody(context);

  void _open(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
