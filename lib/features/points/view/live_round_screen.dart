import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_bar.dart';
import '../../chips/data/chips_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/widgets/match_format.dart';
import '../../pick/data/picks_repository.dart';
import '../../pick/view/round_pick_view.dart';
import '../../players/data/players_repository.dart';
import '../../week/data/week_window.dart';
import '../cubit/live_round_cubit.dart';
import '../data/points_repository.dart';
import '../widgets/round_pager.dart';
import '../widgets/round_points_body.dart';

/// من الهوم: تابين —
///   • نقط الجولة اللي بتتلعب: كل لاعب جاب كام، ومين لعب ومين بيلعب ومين لسه.
///   • تشكيلة الجولة الجاية: تعملها وتغيّرها براحتك لحد الديدلاين (قبل الجولة بساعة).
class LiveRoundScreen extends StatefulWidget {
  const LiveRoundScreen({super.key, required this.userId, this.startOnNext = false});

  final String userId;
  final bool startOnNext;

  @override
  State<LiveRoundScreen> createState() => _LiveRoundScreenState();
}

class _LiveRoundScreenState extends State<LiveRoundScreen> {
  late bool _next = widget.startOnNext;
  final WeekWindow _open = WeekWindow.open();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => LiveRoundCubit(
        userId: widget.userId,
        picks: c.read<PicksRepository>(),
        chips: c.read<ChipsRepository>(),
        points: c.read<PointsRepository>(),
        players: c.read<PlayersRepository>(),
        matches: c.read<MatchesRepository>(),
      )..load(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const StatusArea(),
            Masthead(title: 'جولتي', subtitle: 'MY ROUND', onBack: () => Navigator.pop(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _tab('نقط الجولة', !_next, () => setState(() => _next = false)),
                  const SizedBox(width: 6),
                  _tab('تشكيلة الجولة الجاية', _next, () => setState(() => _next = true)),
                ],
              ),
            ),
            Expanded(
              child: SoftSwitcher(
                child: _next
                    ? Column(
                        key: const ValueKey('next'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Text(
                              '${_open.label} · تقدر تغيّر لحد ${arabicWeekday(_open.deadline)} ${arabicTime(_open.deadline)}',
                              style: AppText.body(11, color: AppColors.neutral700),
                            ),
                          ),
                          Expanded(
                            child: RoundPickView(window: _open, userId: widget.userId),
                          ),
                        ],
                      )
                    : const _LivePoints(key: ValueKey('live')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool on, VoidCallback onTap) => Expanded(
    child: Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: on ? AppColors.accent : AppColors.card,
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
        ),
        child: Text(label, style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
      ),
    ),
  );
}

class _LivePoints extends StatelessWidget {
  const _LivePoints({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveRoundCubit, LiveRoundState>(
      builder: (context, s) {
        if (s.status == LiveRoundStatus.loading) {
          return Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (s.status == LiveRoundStatus.error) {
          return Center(
            child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
          );
        }
        final e = s.entry;
        if (e == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'معملتش تشكيلة للجولة دي (${s.window.label})\nاعمل تشكيلة الجولة الجاية من التاب التاني',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: AppColors.neutral600),
              ),
            ),
          );
        }
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            RoundPager(entry: e),
            RoundPointsBody(entry: e, players: s.players, statusFor: s.statusFor),
          ],
        );
      },
    );
  }
}
