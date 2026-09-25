import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/cubit/players_cubit.dart';
import '../../players/data/availability.dart';
import '../../players/data/models/player.dart';
import '../../players/data/models/player_gw_stat.dart';
import '../../players/data/stats_repository.dart';
import '../../week/data/week_window.dart';
import '../../players/widgets/availability_badge.dart';
import '../../players/data/players_repository.dart';
import '../../shell/cubit/app_nav_cubit.dart';

/// تبويب اللاعيبة — تصفّح كل اللاعيبة ونقاطهم (بلا ميزانية/تحويلات).
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (c) => PlayersCubit(c.read<PlayersRepository>())..load(), child: const _PlayersView());
  }
}

class _PlayersView extends StatefulWidget {
  const _PlayersView();

  @override
  State<_PlayersView> createState() => _PlayersViewState();
}

class _PlayersViewState extends State<_PlayersView> {
  Map<String, PlayerGwStat> _stats = const {};
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // حد حفظ/غيّر تشكيلته → الامتلاك يتحدّث
    // التشكيلات بتتغيّر كتير — نحدّث الامتلاك مرة كل ١٥ ثانية بالكتير
    _sub = liveTable('picks', _loadStats, debounce: const Duration(seconds: 15));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// الامتلاك الحقيقي لكل لاعب في الجولة الحالية.
  Future<void> _loadStats() async {
    try {
      final repo = context.read<StatsRepository>();
      final stats = await repo.windowStats(WeekWindow.current());
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return Column(
      children: [
        const StatusArea(),
        const Masthead(title: 'اللاعيبة', subtitle: 'PLAYERS'),
        Expanded(
          child: BlocBuilder<PlayersCubit, PlayersState>(
            builder: (context, s) {
              if (s.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }
              final players = [...s.players]..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
              if (players.isEmpty) {
                return Center(
                  child: Text('لسه مفيش لاعيبة', style: AppText.body(13, color: AppColors.neutral600)),
                );
              }
              return ListView(
                padding: EdgeInsets.zero,
                children: [for (final p in players) _row(p, () => nav.openPlayer(p))],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(Player p, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            InitialsTile(p.initials, photoUrl: p.imageUrl),
            const SizedBox(width: 11),
            AvailabilityBadge(p.availability, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(14)),
                  Text(
                    p.availability != Availability.ready && (p.news?.isNotEmpty ?? false)
                        ? '${p.team} · ${Availability.statusLine(p.availability)}: ${p.news}'
                        : '${p.team} · ${p.positionAr}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(10, color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${p.totalPoints}', style: AppText.h(18)),
                Text(
                  'امتلاك ${(_stats[p.id]?.ownership ?? 0).toStringAsFixed(0)}%',
                  style: AppText.body(9, color: AppColors.neutral700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
