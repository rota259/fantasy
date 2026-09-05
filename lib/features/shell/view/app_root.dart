import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auction/data/auction_repository.dart';
import '../../auction/data/supabase_auction_repository.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../auth/view/login_screen.dart';
import '../../auth/view/register_screen.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/supabase_events_repository.dart';
import '../../home/cubit/live_feed_cubit.dart';
import '../../leagues/data/leagues_repository.dart';
import '../../manager/data/lineup_repository.dart';
import '../../manager/data/supabase_lineup_repository.dart';
import '../../leagues/data/supabase_leagues_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/supabase_matches_repository.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../../pick/data/picks_repository.dart';
import '../../pick/data/supabase_picks_repository.dart';
import '../../pitch/data/supabase_venues_repository.dart';
import '../../pitch/data/venues_repository.dart';
import '../../players/data/players_repository.dart';
import '../../players/data/supabase_players_repository.dart';
import '../../splash/view/splash_screen.dart';
import '../../squad/cubit/squad_cubit.dart';
import '../../squad/data/profile_repository.dart';
import '../../squad/data/supabase_profile_repository.dart';
import '../cubit/app_nav_cubit.dart';
import 'app_shell.dart';

/// جذر التطبيق: بيوفّر الـ repositories والـ cubits، والمصادقة بتقود التنقّل.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => SupabaseAuthRepository()),
        RepositoryProvider<PlayersRepository>(create: (_) => SupabasePlayersRepository()),
        RepositoryProvider<ProfileRepository>(create: (_) => SupabaseProfileRepository()),
        RepositoryProvider<MatchesRepository>(create: (_) => SupabaseMatchesRepository()),
        RepositoryProvider<LeaguesRepository>(create: (_) => SupabaseLeaguesRepository()),
        RepositoryProvider<EventsRepository>(create: (_) => SupabaseEventsRepository()),
        RepositoryProvider<VenuesRepository>(create: (_) => SupabaseVenuesRepository()),
        RepositoryProvider<AuctionRepository>(create: (_) => SupabaseAuctionRepository()),
        RepositoryProvider<LineupRepository>(create: (_) => SupabaseLineupRepository()),
        RepositoryProvider<PicksRepository>(create: (_) => SupabasePicksRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AppNavCubit()),
          BlocProvider(create: (_) => LiveFeedCubit()),
          BlocProvider(create: (c) => SquadCubit(c.read<PlayersRepository>(), c.read<ProfileRepository>())),
          BlocProvider(create: (c) => AuthCubit(c.read<AuthRepository>())..checkSession()),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthCubit, AuthState>(
              listenWhen: (p, c) => p.status != c.status,
              listener: _onAuthChanged,
            ),
            BlocListener<AppNavCubit, AppNavState>(
              listenWhen: (p, c) => p.route != AppRoute.app && c.route == AppRoute.app,
              listener: (context, _) {
                // وضع demo فقط؛ في الوضع الحقيقي البثّ بيتحمّل مع التشكيلة.
                if (!SupabaseConfig.isConfigured) {
                  context.read<LiveFeedCubit>().startDemo();
                }
              },
            ),
            BlocListener<SquadCubit, SquadState>(
              listenWhen: (p, c) =>
                  c.status == SquadStatus.loaded &&
                  (p.players != c.players || p.captainId != c.captainId),
              listener: (context, s) {
                if (SupabaseConfig.isConfigured) {
                  context
                      .read<LiveFeedCubit>()
                      .loadLive(s.players, s.captainId, context.read<EventsRepository>());
                }
              },
            ),
          ],
          child: BlocBuilder<AppNavCubit, AppNavState>(
            buildWhen: (p, c) => p.route != c.route || p.onboardIndex != c.onboardIndex,
            builder: (context, state) => _screen(state),
          ),
        ),
      ),
    );
  }

  /// دخول ناجح → التطبيق؛ خروج → شاشة الدخول.
  void _onAuthChanged(BuildContext context, AuthState s) {
    final nav = context.read<AppNavCubit>();
    if (s.status == AuthStatus.authenticated) {
      context.read<SquadCubit>().loadForUser(s.user);
      nav.login();
    } else if (s.status == AuthStatus.unauthenticated && nav.state.route == AppRoute.app) {
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
