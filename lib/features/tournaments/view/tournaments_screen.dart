import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_bar.dart';
import '../../../core/zone/zone_scope.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../matches/widgets/match_format.dart';
import '../data/models/tournament.dart';
import '../data/tournaments_repository.dart';
import '../widgets/create_tournament_sheet.dart';
import 'tournament_screen.dart';

/// البطولات في منطقتي — والمدير/الأدمن يعمل بطولة جديدة.
class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  late Future<List<Tournament>> _future = _load();

  Future<List<Tournament>> _load() async {
    final z = ZoneScope.current;
    return z == null ? const [] : context.read<TournamentsRepository>().list(z);
  }

  Future<void> _create() async {
    final id = await showCreateTournamentSheet(context);
    if (id == null || !mounted) return;
    setState(() => _future = _load());
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentScreen(id: id)));
  }

  @override
  Widget build(BuildContext context) {
    final u = context.read<AuthCubit>().state.user;
    final canCreate = u != null && (u.isManager || u.isOrganizer);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'البطولات', subtitle: 'TOURNAMENTS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<Tournament>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const SkeletonList();
                final list = snap.data!;
                return RefreshIndicator(
                  onRefresh: () async => setState(() => _future = _load()),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 14, bottom: 24),
                    children: [
                      if (canCreate)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: FilledButton.icon(
                            onPressed: _create,
                            icon: const Icon(Icons.emoji_events_outlined),
                            label: const Text('بطولة جديدة'),
                          ),
                        ),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(30),
                          child: Text(
                            'مفيش بطولات في منطقتك لسه 🏆',
                            textAlign: TextAlign.center,
                            style: AppText.body(13, color: AppColors.neutral600),
                          ),
                        ),
                      for (final (i, t) in list.indexed) FadeSlideIn(index: i, child: _card(t)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Tournament t) => Pressable(
    onTap: () async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentScreen(id: t.id)));
      if (mounted) setState(() => _future = _load());
    },
    child: Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.tile,
      child: Row(
        children: [
          Text(t.isFinished ? '🏆' : '⚽', style: AppText.h(28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: AppText.h(16)),
                Text(
                  '${t.formatLabel} · ${t.teamCount} فرق · ${arabicWeekday(t.startsAt)} ${t.startsAt.day}/${t.startsAt.month}',
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
                if (t.isFinished && t.champion != null)
                  Text('البطل: ${t.champion}', style: AppText.h(12, color: AppColors.accent))
                else if (t.prize != null)
                  Text('🎁 ${t.prize}', style: AppText.h(12, color: AppColors.bronze)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: t.isRegistration ? AppColors.info : (t.isRunning ? AppColors.accent : AppColors.neutral600),
              borderRadius: AppRadius.sm,
            ),
            child: Text(t.statusLabel, style: AppText.h(10, color: AppColors.white)),
          ),
        ],
      ),
    ),
  );
}
