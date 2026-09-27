import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/motion.dart';
import '../../account/view/account_screen.dart';
import '../../awards/view/awards_overlay.dart';
import '../../challenge/view/challenge_overlay.dart';
import '../../home/view/home_screen.dart';
import '../../leagues/view/leagues_screen.dart';
import '../../market/view/market_screen.dart';
import '../../overlays/view/coach_overlay.dart';
import '../../overlays/view/fixtures_overlay.dart';
import '../../overlays/view/pitch_overlay.dart';
import '../../overlays/view/player_overlay.dart';
import '../../team/view/team_screen.dart';
import '../cubit/app_nav_cubit.dart';
import '../widgets/bottom_tab_bar.dart';

/// هيكل التطبيق بعد الدخول: تابات + شريط سفلي + طبقة overlays فوقهم.
/// التاب بيتبني أول ما اليوزر يفتحه بس (مش الخمسة مع بعض أول ما الأبلكيشن يفتح)، وبعدها بيفضل محفوظ.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _tabs = [HomeScreen(), TeamScreen(), MarketScreen(), LeaguesScreen(), AccountScreen()];
  final _opened = <int>{};

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<AppNavCubit, AppNavState>(
        builder: (context, state) {
          _opened.add(state.tab.index);
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    // كل التابات المفتوحة بتفضل محفوظة، والتبديل بينها بظهور تدريجي
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          if (_opened.contains(i))
                            AnimatedOpacity(
                              opacity: i == state.tab.index ? 1 : 0,
                              duration: Motion.medium,
                              curve: Motion.curve,
                              child: IgnorePointer(
                                ignoring: i != state.tab.index,
                                child: TickerMode(enabled: i == state.tab.index, child: _tabs[i]),
                              ),
                            ),
                      ],
                    ),
                  ),
                  BottomTabBar(current: state.tab, onTap: nav.setTab),
                ],
              ),
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  switchInCurve: Motion.curve,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: state.overlay == AppOverlayView.none
                      ? const SizedBox.shrink(key: ValueKey('none'))
                      : KeyedSubtree(key: ValueKey(state.overlay), child: _overlay(state.overlay)),
                ),
              ),
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
      AppOverlayView.challenge => const ChallengeOverlay(),
      AppOverlayView.awards => const AwardsOverlay(),
      AppOverlayView.fixtures => const FixturesOverlay(),
      AppOverlayView.player => const PlayerOverlay(),
      AppOverlayView.none => const SizedBox.shrink(),
    };
  }
}
