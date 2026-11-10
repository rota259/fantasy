import 'package:flutter/material.dart';
import '../../update/admin_update_screen.dart';
import 'push_check_screen.dart';
import '../../fairplay/view/admin_betting_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../events/data/events_repository.dart';
import '../../integrity/view/admin_organizers_screen.dart';
import '../../integrity/view/admin_review_screen.dart';
import '../../matches/data/matches_repository.dart';
import '../../pitch/view/venue_requests_screen.dart';
import '../../players/data/players_repository.dart';
import '../../teams/view/admin_teams_screen.dart';
import '../../week/view/admin_totw_screen.dart';
import '../data/lineup_repository.dart';
import '../widgets/manager_dashboard.dart';
import 'admin_log_screen.dart';
import '../../logs/view/admin_logs_screen.dart';
import 'manager_availability_screen.dart';
import 'manager_awards_screen.dart';
import 'manager_broadcast_screen.dart';
import 'manager_challenge_screen.dart';
import 'manager_claims_screen.dart';
import 'manager_leagues_screen.dart';
import 'manager_matches_screen.dart';
import 'manager_players_screen.dart';
import 'manager_users_screen.dart';
import 'manager_venues_screen.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/theme/app_spacing.dart';

part 'manager_hub_screen_sections.dart';
part 'manager_hub_screen_sections2.dart';
part 'manager_hub_screen_sections3.dart';

/// لوحة الأدمن: إحصائيات سريعة + كل أدوات الإدارة.
class ManagerHubScreen extends StatelessWidget {
  const ManagerHubScreen({super.key});

  @override
  Widget build(BuildContext context) => _buildBody(context);

  Widget _group(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
    child: Text(t, style: AppText.kicker(color: AppColors.accent)),
  );
}
