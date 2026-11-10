import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../points/view/live_round_screen.dart';
import 'zone_league_screen.dart';
import '../../../core/share/share_card.dart';
import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/prow_row.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../badges/data/badges_repository.dart';
import '../cubit/leagues_cubit.dart';
import '../data/leagues_repository.dart';
import '../widgets/league_dialogs.dart';
import '../widgets/leagues_widgets.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'leagues_screen_sections.dart';

/// تبويب الدوريات: اعمل دوري أو انضم بكود، وشوف الترتيب بالصور والشارات.
class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => LeaguesCubit(c.read<LeaguesRepository>(), c.read<BadgesRepository>())..load(userId),
      child: _LeaguesView(userId: userId),
    );
  }
}

class _LeaguesView extends StatelessWidget {
  const _LeaguesView({this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StatusArea(),
        Masthead(
          title: 'الدوريات',
          subtitle: 'LEAGUES',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _headerBtn('+ دوري', () => _create(context)),
              const SizedBox(width: 6),
              _headerBtn('انضم', () => _join(context)),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<LeaguesCubit, LeaguesState>(
            builder: (context, s) {
              if (s.isLoading) return const SkeletonList();
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  LeaguesHero(rank: s.globalRank > 0 ? '${s.globalRank}' : '—'),
                  // دوري المناطق: منطقتك ضد باقي المناطق
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Pressable(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZoneLeagueScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.navy, AppColors.info]),
                          borderRadius: AppRadius.md,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_city_outlined, size: 26, color: AppColors.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'دوري المناطق — خش شوف منطقتك ترتيبها كام؟',
                                style: AppText.h(14, color: AppColors.white),
                              ),
                            ),
                            Text('›', style: AppText.h(18, color: AppColors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._body(context, s),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
