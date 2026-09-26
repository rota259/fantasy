import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../badges/data/badges_repository.dart';
import '../../badges/data/supabase_badges_repository.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../challenge/data/supabase_challenge_repository.dart';
import '../../chips/data/chips_repository.dart';
import '../../chips/data/supabase_chips_repository.dart';
import '../../claims/data/claims_repository.dart';
import '../../claims/data/supabase_claims_repository.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/supabase_events_repository.dart';
import '../../follow/data/follows_repository.dart';
import '../../follow/data/supabase_follows_repository.dart';
import '../../integrity/data/integrity_repository.dart';
import '../../integrity/data/supabase_integrity_repository.dart';
import '../../leagues/data/leagues_repository.dart';
import '../../leagues/data/supabase_leagues_repository.dart';
import '../../manager/data/admin_repository.dart';
import '../../manager/data/lineup_repository.dart';
import '../../manager/data/supabase_admin_repository.dart';
import '../../manager/data/supabase_lineup_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/supabase_matches_repository.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/data/supabase_notifications_repository.dart';
import '../../pick/data/picks_repository.dart';
import '../../pick/data/supabase_picks_repository.dart';
import '../../pitch/data/bookings_repository.dart';
import '../../pitch/data/reviews_repository.dart';
import '../../pitch/data/supabase_bookings_repository.dart';
import '../../pitch/data/supabase_reviews_repository.dart';
import '../../pitch/data/supabase_venues_repository.dart';
import '../../pitch/data/venues_repository.dart';
import '../../players/data/players_repository.dart';
import '../../players/data/stats_repository.dart';
import '../../players/data/supabase_players_repository.dart';
import '../../players/data/supabase_stats_repository.dart';
import '../../polls/data/polls_repository.dart';
import '../../polls/data/supabase_polls_repository.dart';
import '../../ratings/data/ratings_repository.dart';
import '../../ratings/data/supabase_ratings_repository.dart';
import '../../seasons/data/seasons_repository.dart';
import '../../seasons/data/supabase_seasons_repository.dart';
import '../../squad/data/profile_repository.dart';
import '../../squad/data/supabase_profile_repository.dart';
import '../../teams/data/supabase_teams_repository.dart';
import '../../teams/data/teams_repository.dart';
import '../../week/data/supabase_week_repository.dart';
import '../../week/data/week_repository.dart';
import '../../zones/data/supabase_zones_repository.dart';
import '../../zones/data/zones_repository.dart';

/// كل الـ repositories — فوق الـ MaterialApp عشان أي شاشة (حتى اللي بتتفتح بـ push)
/// تقدر تقرأها بـ context.read.
class AppRepositories extends StatelessWidget {
  const AppRepositories({super.key, required this.child});

  final Widget child;

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
        RepositoryProvider<BookingsRepository>(create: (_) => SupabaseBookingsRepository()),
        RepositoryProvider<LineupRepository>(create: (_) => SupabaseLineupRepository()),
        RepositoryProvider<PicksRepository>(create: (_) => SupabasePicksRepository()),
        RepositoryProvider<WeekRepository>(create: (_) => SupabaseWeekRepository()),
        RepositoryProvider<NotificationsRepository>(create: (_) => SupabaseNotificationsRepository()),
        RepositoryProvider<PollsRepository>(create: (_) => SupabasePollsRepository()),
        RepositoryProvider<StatsRepository>(create: (_) => SupabaseStatsRepository()),
        RepositoryProvider<AdminRepository>(create: (_) => SupabaseAdminRepository()),
        RepositoryProvider<ChipsRepository>(create: (_) => SupabaseChipsRepository()),
        RepositoryProvider<ChallengeRepository>(create: (_) => SupabaseChallengeRepository()),
        RepositoryProvider<FollowsRepository>(create: (_) => SupabaseFollowsRepository()),
        RepositoryProvider<RatingsRepository>(create: (_) => SupabaseRatingsRepository()),
        RepositoryProvider<ClaimsRepository>(create: (_) => SupabaseClaimsRepository()),
        RepositoryProvider<BadgesRepository>(create: (_) => SupabaseBadgesRepository()),
        RepositoryProvider<SeasonsRepository>(create: (_) => SupabaseSeasonsRepository()),
        RepositoryProvider<ReviewsRepository>(create: (_) => SupabaseReviewsRepository()),
        RepositoryProvider<IntegrityRepository>(create: (_) => SupabaseIntegrityRepository()),
        RepositoryProvider<ZonesRepository>(create: (_) => SupabaseZonesRepository()),
        RepositoryProvider<TeamsRepository>(create: (_) => SupabaseTeamsRepository()),
      ],
      child: child,
    );
  }
}
