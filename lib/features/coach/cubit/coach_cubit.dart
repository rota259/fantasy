import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../matches/data/matches_repository.dart';
import '../../players/data/players_repository.dart';
import '../../players/data/stats_repository.dart';
import '../../week/data/week_window.dart';
import '../coach_engine.dart';

part 'coach_state.dart';

/// ViewModel للمدرّب: بيجمع اللاعيبة + إحصائيات الجولة + الماتش الجاي ويبني التقرير.
class CoachCubit extends Cubit<CoachState> {
  CoachCubit(this._players, this._stats, this._matches) : super(const CoachState());

  final PlayersRepository _players;
  final StatsRepository _stats;
  final MatchesRepository _matches;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const CoachState(status: CoachStatus.ready));
      return;
    }
    emit(const CoachState(status: CoachStatus.loading));
    try {
      final players = await _players.fetchMyZone();
      final stats = await _stats.windowStats(WeekWindow.current());
      final upcoming = await _matches.fetchUpcoming();
      final report = CoachEngine.build(
        players: players,
        stats: stats,
        nextTeams: upcoming.isEmpty ? const [] : upcoming.first.teams,
      );
      emit(CoachState(status: CoachStatus.ready, report: report));
    } catch (_) {
      emit(const CoachState(status: CoachStatus.ready));
    }
  }
}
