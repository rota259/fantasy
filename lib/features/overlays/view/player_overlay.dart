import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/overlay_shell.dart';
import '../widgets/player_stats_section.dart';
import '../widgets/player_widgets.dart';

/// تفاصيل اللاعب — بيانات حقيقية للاعب المختار من تبويب «اللاعيبة».
class PlayerOverlay extends StatelessWidget {
  const PlayerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    final player = nav.state.selectedPlayer;

    if (player == null) {
      return OverlayShell(
        title: 'لاعب',
        subtitle: 'PLAYER',
        onBack: nav.back,
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'افتح أي لاعب من تبويب «اللاعيبة» عشان تشوف تفاصيله',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: AppColors.neutral600),
              ),
            ),
          ),
        ],
      );
    }

    return OverlayShell(
      title: 'لاعب',
      subtitle: 'PLAYER',
      onBack: nav.back,
      header: PlayerHeader(onBack: nav.back, player: player),
      children: [
        PlayerStatGrid(player: player),
        PlayerStatsSection(playerId: player.id),
      ],
    );
  }
}
