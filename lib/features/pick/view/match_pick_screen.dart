import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../manager/data/lineup_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../players/data/players_repository.dart';
import '../cubit/match_pick_cubit.dart';
import '../data/picks_repository.dart';
import '../widgets/pick_pitch.dart';
import '../widgets/pick_sheets.dart';

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
    messenger.showSnackBar(SnackBar(
      content: Text(err ?? 'اتحفظت تشكيلتك ✓'),
      backgroundColor: err == null ? AppColors.accent : AppColors.danger,
      duration: Duration(milliseconds: err == null ? 1600 : 4000),
    ));
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
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _counts(s),
                    PickPitch(
                      state: s,
                      teamA: match.teamA,
                      teamB: match.teamB,
                      onSlotTap: locked
                          ? (_) {}
                          : (kind) => showAddPlayerSheet(context, cubit, s, kind, match.teamA, match.teamB),
                      onPlayerTap: locked
                          ? (_) {}
                          : (p) => showPlayerOptionsSheet(context, cubit, s, p),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      child: Text(
                        'القواعد: ٢ من كل فريق + حارس (أي فريق) + ٢ احتياطي + كابتن.\nدوس على أي لاعب عشان تعمله كابتن/احتياطي أو تبدّله.',
                        style: AppText.body(11, color: AppColors.neutral700),
                      ),
                    ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(children: [
        Text('أساسي ${s.startingCount}/5', style: AppText.h(13, color: AppColors.accent)),
        const SizedBox(width: 16),
        Text('احتياطي ${s.benchCount}/2', style: AppText.h(13)),
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
