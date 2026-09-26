import 'package:flutter/material.dart';

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

/// قائمة الماتشات + إنشاء ماتش جديد — الأدمن بيشوف الكل، والمنظّم ماتشاته بس ([organizerId]).
class ManagerMatchesScreen extends StatefulWidget {
  const ManagerMatchesScreen({
    super.key,
    required this.matchesRepo,
    required this.playersRepo,
    required this.eventsRepo,
    required this.lineupRepo,
    this.organizerId,
  });

  final MatchesRepository matchesRepo;
  final PlayersRepository playersRepo;
  final EventsRepository eventsRepo;
  final LineupRepository lineupRepo;
  final String? organizerId;

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

  Future<void> _addMatch() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ManagerAddMatchScreen(matchesRepo: widget.matchesRepo)),
    );
    if (added == true) _reload();
  }

  Future<void> _editMatch(GameMatch m) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerAddMatchScreen(matchesRepo: widget.matchesRepo, editing: m),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(GameMatch m) async {
    final ok = await confirmDeleteMatch(context, m);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await widget.matchesRepo.deleteMatch(m.id);
      if (n == 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('مينفعش تحذف الماتش ده (بدأ أو مش بتاعك)'),
            duration: Duration(milliseconds: 2600),
          ),
        );
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('اتحذف الماتش ✓')));
      _reload();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(dbMessage(e, fallback: 'فشل الحذف')),
          duration: const Duration(milliseconds: 2600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: widget.organizerId == null ? 'إدارة الماتشات' : 'ماتشاتي كمنظّم',
            subtitle: widget.organizerId == null ? 'MANAGER · MATCHES' : 'ORGANIZER',
            onBack: () => Navigator.pop(context),
            trailing: GestureDetector(
              onTap: _addMatch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(border: AppBorders.white(0.5)),
                child: Text('+ ماتش', style: AppText.h(12, color: AppColors.white)),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<GameMatch>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                final matches = snap.data!;
                if (matches.isEmpty) {
                  return Center(
                    child: Text('مفيش ماتشات — اضغط "+ ماتش"', style: AppText.body(13, color: AppColors.neutral600)),
                  );
                }
                return ListView(padding: EdgeInsets.zero, children: [for (final m in matches) _row(m)]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(GameMatch m) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManagerMatchScreen(
            match: m,
            playersRepo: widget.playersRepo,
            eventsRepo: widget.eventsRepo,
            lineupRepo: widget.lineupRepo,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(14))),
                      const SizedBox(width: 6),
                      ReviewStatusChip(match: m),
                    ],
                  ),
                  Text(
                    'GW${m.week} · ${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)} · ${m.isFinished ? 'انتهى ${m.scoreText}' : 'قادم'}',
                    style: AppText.body(10, color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            Text('إدارة ›', style: AppText.h(12, color: AppColors.accent)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _editMatch(m),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined, size: 20, color: AppColors.neutral700),
              ),
            ),
            GestureDetector(
              onTap: () => _confirmDelete(m),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
