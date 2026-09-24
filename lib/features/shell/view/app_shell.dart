import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../account/view/account_screen.dart';
import '../../home/view/home_screen.dart';
import '../../leagues/view/leagues_screen.dart';
import '../../market/view/market_screen.dart';
import '../../overlays/view/coach_overlay.dart';
import '../../overlays/view/fixtures_overlay.dart';
import '../../overlays/view/pitch_overlay.dart';
import '../../overlays/view/player_overlay.dart';
import '../../polls/view/poll_overlay.dart';
import '../../team/view/team_screen.dart';
import '../cubit/app_nav_cubit.dart';
import '../widgets/bottom_tab_bar.dart';

/// هيكل التطبيق بعد الدخول: تابات + شريط سفلي + طبقة overlays فوقهم.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _tabs = [
    HomeScreen(), TeamScreen(), MarketScreen(), LeaguesScreen(), AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<AppNavCubit, AppNavState>(
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: IndexedStack(index: state.tab.index, children: _tabs),
                  ),
                  BottomTabBar(current: state.tab, onTap: nav.setTab),
                ],
              ),
              if (state.overlay != AppOverlayView.none)
                Positioned.fill(child: _overlay(state.overlay)),
            ],
          );
        },
      ),
    );
  }

  Widget _overlay(AppOverlayView o) {
    return switch (o) {
      AppOverlayView.coach => const CoachOverlay(),
      AppOverlayView.pitch => const PitchOverlay(),
      AppOverlayView.challenge => const PollOverlay(kind: 'challenge', title: 'تحدّي الجولة', subtitle: 'CHALLENGE'),
      AppOverlayView.star => const PollOverlay(kind: 'star', title: 'نجم الجولة', subtitle: 'STAR OF THE WEEK'),
      AppOverlayView.fixtures => const FixturesOverlay(),
      AppOverlayView.player => const PlayerOverlay(),
      AppOverlayView.none => const SizedBox.shrink(),
    };
  }
}
