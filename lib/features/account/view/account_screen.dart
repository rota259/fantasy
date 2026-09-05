import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../events/data/events_repository.dart';
import '../../leagues/data/leagues_repository.dart';
import '../../manager/data/lineup_repository.dart';
import '../../manager/view/manager_hub_screen.dart';
import '../../matches/data/matches_repository.dart';
import '../../players/data/players_repository.dart';
import '../cubit/account_cubit.dart';
import '../widgets/account_widgets.dart';

/// تبويب حسابي.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    return BlocProvider(
      create: (c) => AccountCubit(c.read<LeaguesRepository>())..load(user?.id),
      child: Column(
        children: [
          const StatusArea(),
          AccountHeader(user: user),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                BlocBuilder<AccountCubit, AccountState>(
                  builder: (context, s) => AccountStats(
                    user: user,
                    rank: s.rank,
                    live: SupabaseConfig.isConfigured,
                  ),
                ),
                const Divider(color: AppColors.divider, height: 2, thickness: 2),
                if (user?.isManager == true)
                  _settingRow(Icons.admin_panel_settings_outlined, 'لوحة المدير',
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManagerHubScreen(
                                playersRepo: context.read<PlayersRepository>(),
                                matchesRepo: context.read<MatchesRepository>(),
                                eventsRepo: context.read<EventsRepository>(),
                                lineupRepo: context.read<LineupRepository>(),
                              ),
                            ),
                          )),
                _settingRow(Icons.translate, 'اللغة · عربي / English'),
                _settingRow(Icons.notifications_none, 'الإشعارات'),
                _settingRow(Icons.help_outline, 'المساعدة والدعم'),
                _settingRow(Icons.logout, 'تسجيل الخروج',
                    accent: true, onTap: context.read<AuthCubit>().signOut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(IconData icon, String label, {bool accent = false, VoidCallback? onTap}) {
    final color = accent ? AppColors.accent : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.h(13, color: color))),
            if (!accent) Text('›', style: AppText.body(16, color: AppColors.neutral700)),
          ],
        ),
      ),
    );
  }
}
