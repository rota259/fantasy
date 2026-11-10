import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/blink_dot.dart';
import '../../../core/widgets/fdr_chip.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../follow/data/follows_repository.dart';
import '../../follow/widgets/follow_button.dart';
import '../../matches/cubit/matches_cubit.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/view/match_center_screen.dart';
import '../../matches/widgets/match_format.dart';
import '../../ratings/view/match_ratings_screen.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/overlay_shell.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'fixtures_overlay_sections.dart';
part 'fixtures_overlay_sections2.dart';

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
              Padding(padding: EdgeInsets.all(30), child: const SkeletonList())
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

  Widget _dayHeader(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Text(t, style: AppText.kicker()),
  );
}
