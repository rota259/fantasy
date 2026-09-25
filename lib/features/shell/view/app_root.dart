import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/notification_service.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/view/login_screen.dart';
import '../../auth/view/register_screen.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../../splash/view/splash_screen.dart';
import '../../squad/data/profile_repository.dart';
import '../cubit/app_nav_cubit.dart';
import 'app_shell.dart';

/// جذر التطبيق: المصادقة بتقود التنقّل.
/// (الـ repositories والـ cubits العامة متوفّرة فوقه في main.)
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: _onAuthChanged,
      child: BlocBuilder<AppNavCubit, AppNavState>(
        buildWhen: (p, c) => p.route != c.route || p.onboardIndex != c.onboardIndex,
        builder: (context, state) => _screen(state),
      ),
    );
  }

  /// دخول ناجح → التطبيق؛ خروج → شاشة الدخول.
  void _onAuthChanged(BuildContext context, AuthState s) {
    final nav = context.read<AppNavCubit>();
    if (s.status == AuthStatus.authenticated) {
      if (s.user != null) {
        NotificationService.registerToken(s.user!.id, context.read<ProfileRepository>());
      }
      nav.login();
    } else if (s.status == AuthStatus.unauthenticated && nav.state.route == AppRoute.app) {
      NotificationService.unregister();
      nav.logout();
    }
  }

  Widget _screen(AppNavState state) {
    return switch (state.route) {
      AppRoute.splash => const SplashScreen(),
      AppRoute.onboard => OnboardingScreen(index: state.onboardIndex),
      AppRoute.login => const LoginScreen(),
      AppRoute.register => const RegisterScreen(),
      AppRoute.app => const AppShell(),
    };
  }
}
