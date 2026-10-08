import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/tournament_cubit.dart';
import '../data/tournaments_repository.dart';
import '../widgets/tournament_awards_tab.dart';
import '../widgets/tournament_bracket_view.dart';
import '../widgets/tournament_header.dart';
import '../widgets/tournament_matches_tab.dart';
import '../widgets/tournament_table_tab.dart';
import '../widgets/tournament_teams_tab.dart';

/// صفحة البطولة: الفرق · الماتشات · الترتيب · الشجرة · الجوايز وتوقّع البطل.
class TournamentScreen extends StatelessWidget {
  const TournamentScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => TournamentCubit(c.read<TournamentsRepository>(), id, uid)..load(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  String _tab = 'teams';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<TournamentCubit, TournamentState>(
        builder: (context, s) {
          final t = s.tournament;
          final u = context.read<AuthCubit>().state.user;
          final runs = t != null && u != null && (u.isManager || t.createdBy == u.id);
          final tabs = [
            ('teams', 'الفرق'),
            ('matches', 'الماتشات'),
            if (t?.format != 'knockout') ('table', 'الترتيب'),
            if (t?.hasBracket ?? false) ('bracket', 'الشجرة'),
            ('awards', 'الجوايز 🏆'),
          ];
          return Column(
            children: [
              const StatusArea(),
              Masthead(title: t?.name ?? 'البطولة', subtitle: 'TOURNAMENT', onBack: () => Navigator.pop(context)),
              if (s.loading)
                const Expanded(child: SkeletonList())
              else if (t == null)
                Expanded(
                  child: Center(child: Text('البطولة مش موجودة', style: AppText.body(13))),
                )
              else ...[
                TournamentHeader(t: t),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [for (final x in tabs) _chip(x.$1, x.$2)],
                  ),
                ),
                Expanded(
                  child: SoftSwitcher(
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: switch (_tab) {
                        'matches' => TournamentMatchesTab(state: s, runs: runs),
                        'table' => TournamentTableTab(state: s, runs: runs),
                        'bracket' => TournamentBracketView(state: s),
                        'awards' => TournamentAwardsTab(state: s),
                        _ => TournamentTeamsTab(state: s, runs: runs),
                      },
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String v, String label) {
    final on = _tab == v;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6, top: 6),
      child: Pressable(
        onTap: () => setState(() => _tab = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: on ? AppColors.accent : AppColors.card,
            borderRadius: AppRadius.lg,
            border: Border.all(color: on ? AppColors.accent : AppColors.line),
          ),
          child: Text(label, style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
        ),
      ),
    );
  }
}
