import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../data/lineup_repository.dart';
import '../data/models/lineup.dart';

/// (المدير) تشكيلات الكباتن للماتش ده: «طبّقها» بتحطها مكان تشكيلة الفريق، واللي لسه مبعتش «فكّره».
/// بعدها «أبلغ اليوزرز إن التشكيلة نزلت».
class CaptainLineupsBanner extends StatefulWidget {
  const CaptainLineupsBanner({super.key, required this.matchId, required this.teams, required this.onApplied});

  final String matchId;
  final List<String> teams;
  final Future<void> Function() onApplied;

  @override
  State<CaptainLineupsBanner> createState() => _CaptainLineupsBannerState();
}

class _CaptainLineupsBannerState extends State<CaptainLineupsBanner> {
  late final LineupRepository _repo = context.read<LineupRepository>();
  late Future<List<TeamLineup>> _future = _repo.teamLineups(widget.matchId).catchError((_) => const <TeamLineup>[]);

  Future<void> _apply(TeamLineup l) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.applyTeam(widget.matchId, l.team);
      await widget.onApplied();
      if (!mounted) return;
      setState(() => _future = _repo.teamLineups(widget.matchId));
      messenger.showSnackBar(SnackBar(content: Text('اتطبّقت تشكيلة «${l.team}» ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Future<void> _remind(String team) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.remindTeam(widget.matchId, team);
      messenger.showSnackBar(SnackBar(content: Text('وصل لكابتن «$team» تفكير ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<TeamLineup>>(
    future: _future,
    builder: (context, snap) {
      if (!snap.hasData) return const SizedBox.shrink();
      final list = snap.data!;
      final waiting = widget.teams.where((t) => !list.any((l) => l.team == t));
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('📋 تشكيلات الكباتن', style: AppText.h(13, color: AppColors.accent800)),
            for (final l in list)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l.team}: ${l.starters} أساسي + ${l.bench} احتياطي${l.applied ? ' · ✓ متطبّقة' : ''}',
                      style: AppText.body(12),
                    ),
                  ),
                  TextButton(onPressed: () => _apply(l), child: Text(l.applied ? 'طبّقها تاني' : 'طبّقها')),
                ],
              ),
            for (final t in waiting)
              Row(
                children: [
                  Expanded(child: Text('$t: ⏳ الكابتن لسه مبعتش', style: AppText.body(12))),
                  TextButton(onPressed: () => _remind(t), child: const Text('فكّره')),
                ],
              ),
          ],
        ),
      );
    },
  );
}
