part of 'app_nav_cubit.dart';

enum AppRoute { splash, onboard, login, register, app }

enum AppTab { home, team, market, leagues, account }

enum AppOverlayView { none, coach, pitch, challenge, fixtures, player, awards }

class AppNavState extends Equatable {
  const AppNavState({
    this.route = AppRoute.splash,
    this.onboardIndex = 0,
    this.tab = AppTab.home,
    this.overlay = AppOverlayView.none,
    this.selectedPlayer,
  });

  final AppRoute route;
  final int onboardIndex; // 0..2
  final AppTab tab;
  final AppOverlayView overlay;
  final Player? selectedPlayer; // اللاعب المفتوح في overlay اللاعب

  AppNavState copyWith({AppRoute? route, int? onboardIndex, AppTab? tab, AppOverlayView? overlay}) {
    return AppNavState(
      route: route ?? this.route,
      onboardIndex: onboardIndex ?? this.onboardIndex,
      tab: tab ?? this.tab,
      overlay: overlay ?? this.overlay,
      selectedPlayer: selectedPlayer,
    );
  }

  @override
  List<Object?> get props => [route, onboardIndex, tab, overlay, selectedPlayer];
}
