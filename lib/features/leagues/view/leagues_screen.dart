import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/prow_row.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/leagues_cubit.dart';
import '../data/leagues_repository.dart';
import '../data/models/league_standing.dart';
import '../widgets/leagues_widgets.dart';
import '../widgets/leagues_mock.dart';

/// تبويب الدوريات.
class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => LeaguesCubit(c.read<LeaguesRepository>())..load(userId),
      child: _LeaguesView(userId: userId),
    );
  }
}

class _LeaguesView extends StatelessWidget {
  const _LeaguesView({this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StatusArea(),
        Masthead(
          title: 'الدوريات',
          subtitle: 'LEAGUES',
          trailing: GestureDetector(
            onTap: () => _join(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(border: AppBorders.white(0.5)),
              child: Text('+ انضم', style: AppText.h(12, color: AppColors.white)),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<LeaguesCubit, LeaguesState>(
            builder: (context, s) {
              if (s.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }
              final live = SupabaseConfig.isConfigured;
              return Column(
                children: [
                  LeaguesHero(rank: live && s.hasData ? _fmt(s.globalRank) : '12,480'),
                  const LeagueSubTabs(),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: live ? _liveBody(context, s) : leaguesMockBody(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _liveBody(BuildContext context, LeaguesState s) {
    if (!s.hasData) {
      return [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Center(child: Text('لسه مش في أي دوري — انضم بكود', style: AppText.body(13, color: AppColors.neutral600))),
        ),
      ];
    }
    final selected = s.myLeagues.firstWhere(
      (m) => m.league.id == s.selectedLeagueId,
      orElse: () => s.myLeagues.first,
    );
    return [
      for (final ml in s.myLeagues) _leagueRow(context, ml),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text('${selected.league.name} · الترتيب', style: AppText.h(14)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(children: [
          for (final st in s.standings)
            StandingRow(rank: '${st.rank}', name: st.name, pts: '${st.points}', me: st.userId == userId),
        ]),
      ),
    ];
  }

  Widget _leagueRow(BuildContext context, MyLeague ml) {
    final l = ml.league;
    return ProwRow(
      onTap: () => context.read<LeaguesCubit>().selectLeague(l.id),
      leading: InitialsTile(l.name.isNotEmpty ? l.name.substring(0, 1) : '?'),
      title: l.name,
      subtitle: Text('${l.memberCount} مدراء · ${l.typeLabel}',
          style: AppText.body(10, color: AppColors.neutral700)),
      trailing: Text('${ml.userRank}', style: AppText.h(16)),
    );
  }

  Future<void> _join(BuildContext context) {
    final ctrl = TextEditingController();
    final cubit = context.read<LeaguesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('انضم لدوري', style: AppText.h(16)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'كود الدعوة')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final msg = await cubit.join(ctrl.text);
              navigator.pop();
              messenger.showSnackBar(SnackBar(content: Text(msg)));
            },
            child: const Text('انضم'),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
