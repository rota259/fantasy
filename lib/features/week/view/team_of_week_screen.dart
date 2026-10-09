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
import '../../../core/widgets/pentagon_pitch.dart';
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

/// تشكيلة الجولة لمنطقتك: أعلى ٥ نقط على خماسي أزرق — بتنزل بعد ما الجولة تخلص والإدارة تعتمدها.
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
        listenWhen: (p, c) => c.published != null && p.published != c.published,
        listener: (context, s) => _reveal(context, s, auto: true),
        builder: (context, s) {
          final cubit = context.read<TeamOfWeekCubit>();
          final (badge, badgeColor) = s.isPublished
              ? ('معتمدة ✓', PitchColors.grass)
              : s.isCurrent
              ? ('الجولة شغّالة', AppColors.neutral600)
              : ('مستنية اعتماد الإدارة', AppColors.bronze);
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
                        s.window.label,
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

  Widget _body(BuildContext context, TeamOfWeekState s) {
    if (s.isLoading) return const SkeletonList();
    final cubit = context.read<TeamOfWeekCubit>();
    if (!s.isPublished) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              s.isCurrent
                  ? 'الجولة لسه بتتلعب ⚽\nتشكيلة الجولة بتنزل بعد ما الجولة تخلص (السبت ٨ الصبح) والإدارة تعتمدها.'
                  : 'الإدارة بتراجع تشكيلة الجولة دي — هيوصلك إشعار أول ما تنزل.',
              textAlign: TextAlign.center,
              style: AppText.body(13, color: AppColors.neutral700),
            ),
          ),
          if (s.tie != null && s.tied.isNotEmpty)
            TotwTieSection(
              tied: s.tied,
              slots: s.slots,
              poll: s.tie,
              onVote: (id) async {
                final messenger = ScaffoldMessenger.of(context);
                final err = await cubit.voteTie(id);
                if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
              },
            ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Pressable(
            onTap: () => _reveal(context, s),
            child: GoldShine(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text('🎴 اكشف التشكيلة وشيّرها', style: AppText.h(14, color: const Color(0xFF3A2600))),
              ),
            ),
          ),
        ),
        TotwPitch(spots: s.spots, onTap: (p) => _open(context, p, s.window)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Text('ترتيب الجولة', style: AppText.h(15)),
        ),
        for (var i = 0; i < s.ranking.length && i < 15; i++)
          FadeSlideIn(
            index: i,
            child: Pressable(
              behavior: HitTestBehavior.opaque,
              onTap: () => _open(context, s.ranking[i], s.window),
              child: _row(i + 1, s.ranking[i], s.spots.any((x) => x?.id == s.ranking[i].id)),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// الضغط على لاعب = عمل إيه في الجولة (كل ماتش · ضد مين · نقطه).
  void _open(BuildContext context, WeekPlayer p, WeekWindow w) =>
      showPlayerMatchesSheet(context, playerId: p.id, name: p.name, team: p.team, window: w);

  /// صف في الترتيب: اللي دخلوا التشكيلة بدهب بيلمع، والباقي بالأخضر.
  Widget _row(int rank, WeekPlayer p, bool inTeam) => Container(
    margin: AppDecor.tileMargin,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: inTeam
        ? AppDecor.tile.copyWith(border: Border.all(color: const Color(0xFFC9971C), width: 1.4))
        : AppDecor.tile,
    child: Row(
      children: [
        SizedBox(
          width: 24,
          child: Text('$rank', style: AppText.h(13, color: PitchColors.grass)),
        ),
        if (inTeam)
          GoldAvatar(player: p, size: 32)
        else
          Jersey(label: p.initials, size: 34, phase: (p.id.hashCode % 100) / 100),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: AppText.h(14)),
              Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
            ],
          ),
        ),
        Text('${p.points}', style: AppText.h(20, color: inTeam ? const Color(0xFF9C7412) : null)),
      ],
    ),
  );
}
