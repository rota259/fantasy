import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../players/data/models/player.dart';

part 'app_nav_state.dart';

/// آلة الحالة للتنقّل: splash → onboarding → login → app (تابات + overlays).
class AppNavCubit extends Cubit<AppNavState> {
  AppNavCubit() : super(const AppNavState());

  void goOnboard() => emit(state.copyWith(route: AppRoute.onboard));

  void onboardNext() {
    if (state.onboardIndex >= 2) {
      emit(state.copyWith(route: AppRoute.login));
    } else {
      emit(state.copyWith(onboardIndex: state.onboardIndex + 1));
    }
  }

  void onboardSkip() => emit(state.copyWith(route: AppRoute.login));

  void goRegister() => emit(state.copyWith(route: AppRoute.register));

  void goLogin() => emit(state.copyWith(route: AppRoute.login));

  void login() =>
      emit(state.copyWith(route: AppRoute.app, tab: AppTab.home));

  /// تغيير التبويب بيقفل أي overlay مفتوح.
  void setTab(AppTab tab) =>
      emit(state.copyWith(tab: tab, overlay: AppOverlayView.none));

  void openOverlay(AppOverlayView overlay) =>
      emit(state.copyWith(overlay: overlay));

  /// فتح overlay اللاعب مع تمرير اللاعب المختار (null = بيانات ثابتة).
  void openPlayer(Player? player) => emit(AppNavState(
        route: state.route,
        onboardIndex: state.onboardIndex,
        tab: state.tab,
        overlay: AppOverlayView.player,
        selectedPlayer: player,
      ));

  void back() => emit(state.copyWith(overlay: AppOverlayView.none));

  /// تسجيل خروج — رجوع لشاشة الدخول (يتوصّل بـ Supabase لاحقًا).
  void logout() => emit(const AppNavState(route: AppRoute.login));
}
