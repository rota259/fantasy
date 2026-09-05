import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../manager/data/lineup_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../cubit/match_pick_cubit.dart';
import '../data/picks_repository.dart';

class MatchPickScreen extends StatelessWidget {
  const MatchPickScreen({
    super.key,
    required this.match,
    required this.playersRepo,
    required this.picksRepo,
    required this.lineupRepo,
    required this.userId,
  });

  final GameMatch match;
  final PlayersRepository playersRepo;
  final PicksRepository picksRepo;
  final LineupRepository lineupRepo;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MatchPickCubit(playersRepo, picksRepo, lineupRepo, match, userId)..load(),
      child: _View(match: match),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.match});
  final GameMatch match;

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final err = await context.read<MatchPickCubit>().save();
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'اتحفظت تشكيلتك ✓')));
    if (err == null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final locked = match.isLocked;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: '${match.teamA} ضد ${match.teamB}',
            subtitle: 'اختر تشكيلتك · PICK',
            onBack: () => Navigator.pop(context),
          ),
          _deadlineBar(locked),
          Expanded(
            child: BlocBuilder<MatchPickCubit, MatchPickState>(
              builder: (context, s) {
                if (s.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (s.players.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text('المدير لسه منزّلش تشكيلة الماتش',
                          textAlign: TextAlign.center,
                          style: AppText.body(13, color: AppColors.neutral600)),
                    ),
                  );
                }
                final cubit = context.read<MatchPickCubit>();
                final teamA = s.players.where((p) => p.team == match.teamA).toList();
                final teamB = s.players.where((p) => p.team == match.teamB).toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _counts(s),
                    const SizedBox(height: 8),
                    Text('القواعد: ٢ من كل فريق + حارس (أي فريق) + ٢ احتياطي + كابتن',
                        style: AppText.body(11, color: AppColors.neutral700)),
                    const SizedBox(height: 12),
                    _teamHeader(match.teamA),
                    for (final p in teamA) _row(cubit, s, p, locked),
                    const SizedBox(height: 8),
                    _teamHeader(match.teamB),
                    for (final p in teamB) _row(cubit, s, p, locked),
                  ],
                );
              },
            ),
          ),
          if (!locked) _saveBar(context),
        ],
      ),
    );
  }

  Widget _deadlineBar(bool locked) {
    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: Text(
        locked ? 'التشكيلة اتقفلت' : 'يقفل ${arabicWeekday(match.deadline)} ${arabicTime(match.deadline)}',
        style: AppText.h(11, color: locked ? AppColors.neutral400 : AppColors.accent400),
      ),
    );
  }

  Widget _counts(MatchPickState s) {
    return Row(children: [
      Text('أساسي ${s.startingCount}/5', style: AppText.h(13, color: AppColors.accent)),
      const SizedBox(width: 16),
      Text('احتياطي ${s.benchCount}/2', style: AppText.h(13)),
    ]);
  }

  Widget _teamHeader(String name) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(name, style: AppText.kicker(color: AppColors.accent)),
      );

  Widget _row(MatchPickCubit cubit, MatchPickState s, Player p, bool locked) {
    final status = s.sel[p.id] ?? 'out';
    final isCap = s.captainId == p.id;
    Widget opt(String label, String value) => GestureDetector(
          onTap: locked ? null : () => cubit.setStatus(p.id, value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: status == value ? AppColors.accent : null,
              border: Border.all(color: status == value ? AppColors.accent : AppColors.divider, width: 2),
            ),
            child: Text(label, style: AppText.h(10, color: status == value ? AppColors.white : AppColors.ink)),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        if (status == 'starting')
          GestureDetector(
            onTap: locked ? null : () => cubit.setCaptain(p.id),
            child: Container(
              width: 24, height: 24, alignment: Alignment.center,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: isCap ? AppColors.accent : null,
                border: Border.all(color: AppColors.black, width: 2),
              ),
              child: Text('C', style: AppText.h(10, color: isCap ? AppColors.white : AppColors.ink)),
            ),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: AppText.h(13)),
            Text(p.positionAr, style: AppText.body(9, color: AppColors.neutral700)),
          ]),
        ),
        opt('أساسي', 'starting'),
        const SizedBox(width: 4),
        opt('احتياطي', 'bench'),
        const SizedBox(width: 4),
        opt('بره', 'out'),
      ]),
    );
  }

  Widget _saveBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => _save(context),
          child: Container(
            color: AppColors.accent,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: Text('احفظ التشكيلة', style: AppText.h(14, color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}
