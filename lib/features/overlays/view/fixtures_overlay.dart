import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/blink_dot.dart';
import '../../../core/widgets/fdr_chip.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../follow/data/follows_repository.dart';
import '../../follow/widgets/follow_button.dart';
import '../../matches/cubit/matches_cubit.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../ratings/view/match_ratings_screen.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/overlay_shell.dart';

/// الماتشات: القادمة (+ تابع لايف) وآخر النتايج (+ قيّم اللاعيبة).
class FixturesOverlay extends StatelessWidget {
  const FixturesOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => MatchesCubit(c.read<MatchesRepository>(), c.read<FollowsRepository>(), userId)..load(),
      child: _FixturesView(userId: userId),
    );
  }
}

class _FixturesView extends StatelessWidget {
  const _FixturesView({this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return BlocBuilder<MatchesCubit, MatchesState>(
      builder: (context, s) {
        final next = s.matches.isEmpty ? null : s.matches.first; // مرتّبة بالوقت
        return OverlayShell(
          title: 'الماتشات',
          subtitle: 'FIXTURES · تابع لايف (٣ في اليوم)',
          onBack: nav.back,
          children: [
            if (next != null) _deadline(next),
            if (s.isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              )
            else if (s.matches.isEmpty)
              _empty()
            else
              ..._upcoming(context, s),
            if (!s.isLoading && s.results.isNotEmpty) ...[
              _dayHeader('آخر النتايج'),
              for (final m in s.results) _result(context, m),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _deadline(GameMatch m) {
    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: Row(
        children: [
          const BlinkDot(color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            'يقفل ${arabicWeekday(m.deadline)} ${arabicTime(m.deadline)} · اختر قبلها',
            style: AppText.h(11, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  List<Widget> _upcoming(BuildContext context, MatchesState s) {
    final groups = <String, List<GameMatch>>{};
    for (final m in s.matches) {
      groups.putIfAbsent('${arabicWeekday(m.dateTime)} ${m.dateTime.day}/${m.dateTime.month}', () => []).add(m);
    }
    return [
      for (final entry in groups.entries) ...[
        _dayHeader(entry.key),
        for (final m in entry.value) _row(context, m, s.follows.contains(m.id)),
      ],
      _legend(),
    ];
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.all(30),
    child: Center(
      child: Text('مفيش ماتشات قادمة', style: AppText.body(13, color: AppColors.neutral600)),
    ),
  );

  Widget _dayHeader(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Text(t, style: AppText.kicker()),
  );

  Widget _row(BuildContext context, GameMatch m, bool following) {
    final uid = userId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          FdrChip(m.fdr),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${m.teamA} ', style: AppText.h(13)),
                      TextSpan(
                        text: 'ضد',
                        style: AppText.body(13, color: AppColors.neutral700),
                      ),
                      TextSpan(text: ' ${m.teamB}', style: AppText.h(13)),
                    ],
                  ),
                ),
                Text(
                  '${arabicTime(m.dateTime)}${m.isChallenge ? ' · 🎯 تحدّي الجولة' : ''}',
                  style: AppText.body(10, color: AppColors.neutral600),
                ),
              ],
            ),
          ),
          if (uid != null)
            FollowButton(
              matchId: m.id,
              userId: uid,
              following: following,
              onChanged: (on) => context.read<MatchesCubit>().setFollow(m.id, on),
            ),
        ],
      ),
    );
  }

  /// ماتش خلص: النتيجة + تقييم الجمهور (مفتوح ٢٤ ساعة) أو نتيجة التقييم.
  Widget _result(BuildContext context, GameMatch m) {
    final uid = userId;
    final canRate = m.ratingOpen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(m.teamA, textAlign: TextAlign.end, style: AppText.h(13)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: AppColors.black,
            child: Text(m.scoreText.isEmpty ? '—' : m.scoreText, style: AppText.h(14, color: AppColors.white)),
          ),
          Expanded(child: Text(m.teamB, style: AppText.h(13))),
          if (uid != null && (canRate || m.motmDone))
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchRatingsScreen(match: m, userId: uid),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                color: canRate ? AppColors.accent : null,
                decoration: canRate ? null : BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
                child: Text(
                  canRate ? 'قيّم ⭐' : 'رجل الماتش',
                  style: AppText.h(10, color: canRate ? AppColors.white : AppColors.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          Text(
            'FDR: ',
            style: AppText.body(10, color: AppColors.neutral700, weight: FontWeight.w600),
          ),
          const FdrChip(2, size: 20),
          Text(' سهل   ', style: AppText.body(10, color: AppColors.neutral700)),
          const FdrChip(5, size: 20),
          Text(' صعب', style: AppText.body(10, color: AppColors.neutral700)),
        ],
      ),
    );
  }
}
