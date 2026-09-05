import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/models/player.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../squad/cubit/squad_cubit.dart';
import '../widgets/overlay_shell.dart';
import '../widgets/player_widgets.dart';

class PlayerOverlay extends StatelessWidget {
  const PlayerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    final player = nav.state.selectedPlayer;
    return OverlayShell(
      title: 'لاعب',
      subtitle: 'PLAYER',
      onBack: nav.back,
      header: PlayerHeader(onBack: nav.back, player: player),
      bottomBar: OverlayActionBar(
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _addAndClose(context, player),
              child: Container(
                color: AppColors.accent,
                padding: const EdgeInsets.all(11),
                alignment: Alignment.center,
                child: Text('أضِف للفريق +', style: AppText.h(14, color: AppColors.white)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: nav.back,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(border: Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 2)),
              child: Text('قارن', style: AppText.h(14, color: AppColors.white)),
            ),
          ),
        ]),
      ),
      children: [
        PlayerStatGrid(player: player),
        // رسم آخر-5 والماتشات الجاية بيانات ثابتة — تظهر للعرض التوضيحي فقط.
        if (player == null) ...[
          _header('آخر 5 جولات'),
          const PlayerLast5(),
          _header('الماتشات الجاية'),
          const PlayerNextFixtures(),
        ],
      ],
    );
  }

  void _addAndClose(BuildContext context, Player? player) {
    if (player != null) {
      final err = context.read<SquadCubit>().addPlayer(player);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'اتضاف ${player.name} لفريقك'),
        duration: const Duration(milliseconds: 1400),
      ));
    }
    context.read<AppNavCubit>().back();
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
        child: Text(t, style: AppText.h(13)),
      );
}
