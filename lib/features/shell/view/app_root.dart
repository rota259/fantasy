import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/supabase/live_hub.dart';
import '../../../core/zone/zone_scope.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/view/login_screen.dart';
import '../../auth/view/register_screen.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../../splash/view/splash_screen.dart';
import '../../squad/data/profile_repository.dart';
import '../../organizer/view/organizer_shell.dart';
import '../../auth/view/banned_screen.dart';
import '../../zones/view/zone_required_screen.dart';
import '../cubit/app_nav_cubit.dart';
import 'app_shell.dart';

/// جذر التطبيق: المصادقة بتقود التنقّل.
/// (الـ repositories والـ cubits العامة متوفّرة فوقه في main.)
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) => p.status != c.status || p.user?.zoneId != c.user?.zoneId,
      listener: _onAuthChanged,
      child: BlocBuilder<AppNavCubit, AppNavState>(
        buildWhen: (p, c) => p.route != c.route || p.onboardIndex != c.onboardIndex,
        builder: (context, state) => _screen(state),
      ),
    );
  }

  /// دخول ناجح → التطبيق؛ خروج → شاشة الدخول. المنطقة بتفلتر كل حاجة + إشعاراتها.
  void _onAuthChanged(BuildContext context, AuthState s) {
    final nav = context.read<AppNavCubit>();
    ZoneScope.current = s.user?.zoneId;
    if (s.status == AuthStatus.authenticated) {
      NotificationService.setZone(s.user?.zoneId);
      if (s.user != null) LiveHub.connect(userId: s.user!.id, zoneId: s.user!.zoneId);
      if (s.user != null) {
        NotificationService.registerToken(s.user!.id, context.read<ProfileRepository>());
      }
      nav.login();
    } else if (s.status == AuthStatus.unauthenticated && nav.state.route == AppRoute.app) {
      NotificationService.unregister();
      LiveHub.disconnect();
      nav.logout();
    }
  }

  Widget _screen(AppNavState state) {
    return switch (state.route) {
      AppRoute.splash => const SplashScreen(),
      AppRoute.onboard => OnboardingScreen(index: state.onboardIndex),
      AppRoute.login => const LoginScreen(),
      AppRoute.register => const RegisterScreen(),
      AppRoute.app => const _ZoneGate(),
    };
  }
}

/// الحساب من غير منطقة → يختارها الأول. تغيير المنطقة بيبني الشاشات من جديد (كل حاجة تتفلتر بيها).
class _ZoneGate extends StatelessWidget {
  const _ZoneGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) =>
          p.user?.zoneId != c.user?.zoneId || p.user?.role != c.user?.role || p.user?.isActive != c.user?.isActive,
      builder: (context, s) {
        final user = s.user;
        ZoneScope.current = user?.zoneId; // قبل ما الشاشات تحمّل
        if (user != null && !user.isActive) return const BannedScreen();
        if (user != null && user.zoneId == null) return const ZoneRequiredScreen();
        // مدير المنطقة ليه أبلكيشن شغل لوحده (منطقتي + حسابي)
        final shell = (user?.isOrganizer ?? false) ? const OrganizerShell() : const AppShell();
        return KeyedSubtree(key: ValueKey((user?.zoneId, user?.role)), child: shell);
      },
    );
  }
}
