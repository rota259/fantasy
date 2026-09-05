import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/cubit/players_cubit.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../squad/cubit/squad_cubit.dart';
import '../widgets/market_widgets.dart';

/// تبويب السوق — التحويلات. بيانات حقيقية من Supabase مع fallback للـ mock.
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => PlayersCubit(c.read<PlayersRepository>())..load(),
      child: const _MarketView(),
    );
  }
}

class _MarketView extends StatelessWidget {
  const _MarketView();

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return Column(
      children: [
        const StatusArea(),
        Masthead(
          title: 'السوق',
          subtitle: 'TRANSFERS',
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('1.6م', style: AppText.h(16, color: AppColors.white)),
              Text('الرصيد',
                  style: AppText.body(8, color: AppColors.white.withValues(alpha: 0.85))),
            ],
          ),
        ),
        const MarketSearch(),
        const MarketFilters(),
        Expanded(
          child: BlocBuilder<PlayersCubit, PlayersState>(
            builder: (context, s) {
              if (s.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              final squad = context.watch<SquadCubit>();
              // بيانات حقيقية لو موجودة (إضافة فعّالة)، وإلا الـ mock.
              final rows = s.players.isNotEmpty
                  ? [
                      for (final pl in s.players)
                        MarketRow(
                          p: MarketPlayer.fromPlayer(pl),
                          onTap: () => nav.openPlayer(pl),
                          inSquad: squad.state.players.any((x) => x.id == pl.id),
                          onAdd: () => _add(context, pl),
                        ),
                    ]
                  : [
                      for (final m in marketPlayers)
                        MarketRow(p: m, onTap: () => nav.openPlayer(null)),
                    ];
              return ListView(padding: EdgeInsets.zero, children: rows);
            },
          ),
        ),
        _actionBar(),
      ],
    );
  }

  void _add(BuildContext context, Player pl) {
    final err = context.read<SquadCubit>().addPlayer(pl);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'اتضاف ${pl.name} لفريقك'),
      duration: const Duration(milliseconds: 1400),
    ));
  }

  Widget _actionBar() {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('تحويل واحد · التالي −4 نقاط',
                  style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.7), weight: FontWeight.w600)),
              Text('1 مجاني', style: AppText.h(13, color: AppColors.accent400)),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            color: AppColors.accent,
            padding: const EdgeInsets.all(11),
            alignment: Alignment.center,
            child: Text('أكّد التحويلات', style: AppText.h(14, color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
