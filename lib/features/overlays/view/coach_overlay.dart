import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../coach/coach_engine.dart';
import '../../coach/cubit/coach_cubit.dart';
import '../../matches/data/matches_repository.dart';
import '../../players/data/players_repository.dart';
import '../../players/data/stats_repository.dart';
import '../../players/widgets/availability_badge.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/overlay_shell.dart';
import '../../../core/widgets/motion.dart';

/// المدرّب — نصايح بالقواعد من داتا التطبيق (فورمة/امتلاك/دخول وخروج/حالة).
class CoachOverlay extends StatelessWidget {
  const CoachOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) =>
          CoachCubit(c.read<PlayersRepository>(), c.read<StatsRepository>(), c.read<MatchesRepository>())..load(),
      child: const _CoachView(),
    );
  }
}

class _CoachView extends StatelessWidget {
  const _CoachView();

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return BlocBuilder<CoachCubit, CoachState>(
      builder: (context, s) {
        final r = s.report;
        return OverlayShell(
          title: 'المدرّب',
          subtitle: 'COACH · من داتا الجولة',
          onBack: nav.back,
          children: s.isLoading
              ? [
                  Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                  ),
                ]
              : (r == null || (r.captain == null && r.sections.isEmpty))
              ? [
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'لسه مفيش داتا كفاية — بعد أول ماتشات وأحداث هتظهر النصايح',
                        textAlign: TextAlign.center,
                        style: AppText.body(13, color: AppColors.neutral600),
                      ),
                    ),
                  ),
                ]
              : [
                  if (r.captain != null) _captain(nav, r),
                  for (final sec in r.sections) ..._section(nav, sec),
                  const SizedBox(height: 16),
                ],
        );
      },
    );
  }

  Widget _captain(AppNavCubit nav, CoachReport r) {
    final p = r.captain!;
    return Pressable(
      onTap: () => nav.openPlayer(p),
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 16, 18, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              color: AppColors.accent,
              child: Text('C', style: AppText.h(20, color: AppColors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الكابتن المقترح', style: AppText.kicker(color: AppColors.accent400)),
                  Text('${p.name} · ${p.team}', style: AppText.h(16, color: AppColors.white)),
                  Text(r.captainReason, style: AppText.body(10, color: AppColors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _section(AppNavCubit nav, CoachSection sec) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 2),
      child: Text(sec.title, style: AppText.h(15)),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
      child: Text(sec.hint, style: AppText.body(10, color: AppColors.neutral600)),
    ),
    for (final it in sec.items)
      Pressable(
        behavior: HitTestBehavior.opaque,
        onTap: () => nav.openPlayer(it.player),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              InitialsTile(it.player.initials, size: 30, photoUrl: it.player.imageUrl),
              const SizedBox(width: 8),
              AvailabilityBadge(it.player.availability, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(it.player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(13)),
              ),
              Text(it.value, style: AppText.h(12, color: AppColors.accent)),
            ],
          ),
        ),
      ),
  ];
}
