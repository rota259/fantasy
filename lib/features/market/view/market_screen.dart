import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/cubit/players_cubit.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../shell/cubit/app_nav_cubit.dart';

/// تبويب اللاعيبة — تصفّح كل اللاعيبة ونقاطهم (بلا ميزانية/تحويلات).
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => PlayersCubit(c.read<PlayersRepository>())..load(),
      child: const _PlayersView(),
    );
  }
}

class _PlayersView extends StatelessWidget {
  const _PlayersView();

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return Column(
      children: [
        const StatusArea(),
        const Masthead(title: 'اللاعيبة', subtitle: 'PLAYERS'),
        Expanded(
          child: BlocBuilder<PlayersCubit, PlayersState>(
            builder: (context, s) {
              if (s.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }
              final players = [...s.players]..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
              if (players.isEmpty) {
                return Center(child: Text('لسه مفيش لاعيبة', style: AppText.body(13, color: AppColors.neutral600)));
              }
              return ListView(
                padding: EdgeInsets.zero,
                children: [for (final p in players) _row(p, () => nav.openPlayer(p))],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(Player p, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: Row(children: [
          InitialsTile(p.initials),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: AppText.h(14)),
              Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
            ]),
          ),
          Text('${p.totalPoints}', style: AppText.h(18)),
        ]),
      ),
    );
  }
}
