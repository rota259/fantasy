import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../events/data/events_repository.dart';
import '../../integrity/widgets/review_status_chip.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../players/data/players_repository.dart';
import '../data/lineup_repository.dart';
import '../widgets/delete_match_dialog.dart';
import 'manager_add_match_screen.dart';
import 'manager_match_screen.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'manager_matches_screen_sections.dart';

/// قائمة الماتشات + إنشاء ماتش جديد — الأدمن بيشوف الكل، والمدير منطقةه بس ([organizerId]).
class ManagerMatchesScreen extends StatefulWidget {
  const ManagerMatchesScreen({
    super.key,
    required this.matchesRepo,
    required this.playersRepo,
    required this.eventsRepo,
    required this.lineupRepo,
    this.organizerId,
    this.finished,
  });

  final MatchesRepository matchesRepo;
  final PlayersRepository playersRepo;
  final EventsRepository eventsRepo;
  final LineupRepository lineupRepo;
  final String? organizerId;

  /// فلتر من لوحة الأدمن: true = اللي خلصت · false = الجاية · null = الكل.
  final bool? finished;

  @override
  State<ManagerMatchesScreen> createState() => _ManagerMatchesScreenState();
}

class _ManagerMatchesScreenState extends State<ManagerMatchesScreen> {
  late Future<List<GameMatch>> _future = _fetch();

  Future<List<GameMatch>> _fetch() {
    final org = widget.organizerId;
    return org == null ? widget.matchesRepo.fetchAll() : widget.matchesRepo.fetchOrganizedBy(org);
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: widget.organizerId == null ? 'إدارة الماتشات' : 'ماتشاتي كمدير',
            subtitle: widget.organizerId == null ? 'ADMIN · MATCHES' : 'ORGANIZER',
            onBack: () => Navigator.pop(context),
            trailing: Pressable(
              onTap: _addMatch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(borderRadius: AppRadius.md, border: AppBorders.white(0.5)),
                child: Text('+ ماتش', style: AppText.h(12, color: AppColors.white)),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<GameMatch>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SkeletonList();
                }
                final f = widget.finished;
                final matches = f == null ? snap.data! : snap.data!.where((m) => m.isFinished == f).toList();
                if (matches.isEmpty) {
                  return Center(
                    child: EmptyState(
                      icon: Icons.sports_soccer,
                      title: 'مفيش ماتشات',
                      hint: 'اضغط «+ ماتش» فوق عشان تعمل أول ماتش',
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  children: [for (final m in matches) _row(m)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
