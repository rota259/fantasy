import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../points/widgets/player_matches_sheet.dart';
import '../data/week_window.dart';
import '../../../core/widgets/jersey.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/fx/gold_shine.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/formation_pitch.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../polls/data/polls_repository.dart';
import '../../zones/data/zones_repository.dart';
import '../../../core/zone/zone_scope.dart';
import '../cubit/team_of_week_cubit.dart';
import '../data/models/week_player.dart';
import '../data/week_repository.dart';
import '../widgets/totw_pitch.dart';
import '../widgets/totw_tie_section.dart';
import 'totw_reveal_screen.dart';
import '../../../core/widgets/motion.dart';
import '../../matches/widgets/match_format.dart';

part 'team_of_week_screen_sections.dart';
part 'team_of_week_tabs.dart';

/// تشكيلة الجولة لمنطقتك: أعلى ٥ نقط (حارس + ٤) من الماتشات المعتمدة.
///   تابين: «اللي خلصت» (نهائية — مبتتغيّرش) و«الحالية» (لايف لحد دلوقتي — بتتغيّر مع كل ماتش يتعتمد).
class TeamOfWeekScreen extends StatelessWidget {
  const TeamOfWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => TeamOfWeekCubit(c.read<WeekRepository>(), c.read<PollsRepository>(), userId)..load(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  /// كشف التشكيلة (زي فتح الباكات) — أوتوماتيك أول مرة تشوف تشكيلة جديدة، وبعدها من الزرار.
  static Future<void> _reveal(BuildContext context, TeamOfWeekState s, {bool auto = false}) async {
    final team = s.published;
    if (team == null || team.isEmpty) return;
    final key = 'totw_seen_${s.window.cutoff.millisecondsSinceEpoch}_${team.map((p) => p.id).join(',')}';
    if (auto) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool(key) ?? false) return;
        await prefs.setBool(key, true);
      } catch (_) {}
    }
    if (!context.mounted) return;
    final zone = await context.read<ZonesRepository>().byId(ZoneScope.current).catchError((_) => null);
    if (!context.mounted) return;
    await TotwRevealScreen.open(
      context,
      team,
      [?zone?.label, s.window.label].join(' · '),
      refCode: context.read<AuthCubit>().state.user?.refCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocConsumer<TeamOfWeekCubit, TeamOfWeekState>(
        // الكشف الأوتوماتيك للتشكيلة النهائية بس (اللايف بتتغيّر كتير)
        listenWhen: (p, c) => !c.isCurrent && c.published != null && p.published != c.published,
        listener: (context, s) => _reveal(context, s, auto: true),
        builder: (context, s) {
          final cubit = context.read<TeamOfWeekCubit>();
          final (badge, badgeColor) = s.isCurrent ? ('لايف', AppColors.danger) : ('نهائية ✓', PitchColors.grass);
          return Column(
            children: [
              const StatusArea(),
              Masthead(
                title: 'تشكيلة الجولة',
                subtitle: 'TEAM OF THE WEEK',
                onBack: () => Navigator.pop(context),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Pressable(
                      onTap: cubit.previous,
                      child: Text('‹  ', style: AppText.h(20, color: AppColors.white)),
                    ),
                    Pressable(
                      onTap: s.isCurrent ? null : cubit.next,
                      child: Text(
                        '  ›',
                        style: AppText.h(20, color: s.isCurrent ? AppColors.neutral600 : AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              _tabs(context, s),
              Container(
                width: double.infinity,
                color: PitchColors.forest,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: AppRadius.sm),
                      child: Text(badge, style: AppText.h(10, color: AppColors.white)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.isCurrent && s.fetchedAt != null
                            ? '${s.window.label} · آخر تحديث ${arabicTime(s.fetchedAt!)}'
                            : s.window.label,
                        style: AppText.body(10, color: AppColors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context, s)),
            ],
          );
        },
      ),
    );
  }
}
