import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../events/data/events_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/players_repository.dart';
import '../cubit/manager_match_cubit.dart';
import '../data/admin_repository.dart';
import '../data/lineup_repository.dart';
import '../widgets/match_events_section.dart';
import '../widgets/match_lineup_section.dart';
import '../widgets/match_picks_section.dart';
import '../widgets/match_result_section.dart';

/// (مدير) إدارة ماتش: التشكيلة · الأحداث · النتيجة · مين نزّل تشكيلته.
class ManagerMatchScreen extends StatelessWidget {
  const ManagerMatchScreen({
    super.key,
    required this.match,
    required this.playersRepo,
    required this.eventsRepo,
    required this.lineupRepo,
  });

  final GameMatch match;
  final PlayersRepository playersRepo;
  final EventsRepository eventsRepo;
  final LineupRepository lineupRepo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => ManagerMatchCubit(playersRepo, eventsRepo, lineupRepo, c.read<AdminRepository>(), match)..load(),
      child: _View(match: match),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.match});
  final GameMatch match;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  static const _tabs = [('lineup', 'التشكيلة'), ('events', 'الأحداث'), ('result', 'النتيجة'), ('picks', 'اليوزرز')];
  String _mode = 'lineup';

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: '${m.teamA} ضد ${m.teamB}',
            subtitle: 'إدارة الماتش · MANAGE',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: BlocBuilder<ManagerMatchCubit, ManagerMatchState>(
              builder: (context, s) {
                if (s.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                final cubit = context.read<ManagerMatchCubit>();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < _tabs.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          _tab(_tabs[i].$2, _tabs[i].$1),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    switch (_mode) {
                      'lineup' => MatchLineupSection(match: m, cubit: cubit, state: s),
                      'events' => MatchEventsSection(cubit: cubit, state: s),
                      'result' => MatchResultSection(match: m),
                      _ => MatchPicksSection(match: m),
                    },
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, String value) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: Container(
        padding: const EdgeInsets.all(11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _mode == value ? AppColors.accent : null,
          border: Border.all(color: _mode == value ? AppColors.accent : AppColors.black, width: 2),
        ),
        child: Text(label, style: AppText.h(13, color: _mode == value ? AppColors.white : AppColors.ink)),
      ),
    ),
  );
}
