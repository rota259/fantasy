import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/data/models/app_user.dart';
import '../../events/data/events_repository.dart';
import '../../leagues/data/leagues_repository.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../points/points_engine.dart';
import '../../squad/data/profile_repository.dart';

part 'challenge_state.dart';

/// نتيجة المواجهة.
class ChallengeResult {
  const ChallengeResult({
    required this.meName,
    required this.mePoints,
    required this.meCaptainPts,
    required this.oppName,
    required this.oppPoints,
    required this.oppCaptainPts,
  });

  final String meName;
  final int mePoints;
  final int meCaptainPts;
  final String oppName;
  final int oppPoints;
  final int oppCaptainPts;

  bool get meWins => mePoints >= oppPoints;
}

/// ViewModel للتحدّي — يقارن نقاط جولتك بأول خصم في دوريك.
class ChallengeCubit extends Cubit<ChallengeState> {
  ChallengeCubit(this._leagues, this._profiles, this._players, this._events)
      : super(const ChallengeState());

  final LeaguesRepository _leagues;
  final ProfileRepository _profiles;
  final PlayersRepository _players;
  final EventsRepository _events;

  Future<void> load(AppUser? me, List<Player> mySquad, String? myCaptainId) async {
    if (!SupabaseConfig.isConfigured || me == null || mySquad.isEmpty) {
      emit(const ChallengeState(status: ChallengeStatus.loaded));
      return;
    }
    emit(const ChallengeState(status: ChallengeStatus.loading));
    try {
      final leagues = await _leagues.myLeagues(me.id);
      if (leagues.isEmpty) return emit(const ChallengeState(status: ChallengeStatus.loaded));

      final standings = await _leagues.standings(leagues.first.league.id);
      final rivals = standings.where((s) => s.userId != me.id).toList();
      if (rivals.isEmpty) return emit(const ChallengeState(status: ChallengeStatus.loaded));

      final opp = await _profiles.fetchProfile(rivals.first.userId);
      if (opp == null) return emit(const ChallengeState(status: ChallengeStatus.loaded));

      final oppSquad = await _players.fetchByIds(opp.team);
      final myEvents = await _events.fetchForPlayers(mySquad.map((p) => p.id).toList());
      final oppEvents = await _events.fetchForPlayers(oppSquad.map((p) => p.id).toList());

      final result = ChallengeResult(
        meName: me.name,
        mePoints: PointsEngine.squadPoints(mySquad, myCaptainId, myEvents),
        meCaptainPts: PointsEngine.captainContribution(_find(mySquad, myCaptainId), myEvents),
        oppName: opp.name,
        oppPoints: PointsEngine.squadPoints(oppSquad, opp.captainId, oppEvents),
        oppCaptainPts: PointsEngine.captainContribution(_find(oppSquad, opp.captainId), oppEvents),
      );
      emit(ChallengeState(status: ChallengeStatus.loaded, result: result));
    } catch (_) {
      emit(const ChallengeState(status: ChallengeStatus.loaded));
    }
  }

  Player? _find(List<Player> squad, String? id) {
    if (id == null) return null;
    for (final p in squad) {
      if (p.id == id) return p;
    }
    return null;
  }
}
