import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../data/models/week_player.dart';
import '../data/week_repository.dart';

part 'team_of_week_state.dart';

/// ViewModel لتشكيلة الأسبوع.
class TeamOfWeekCubit extends Cubit<TeamOfWeekState> {
  TeamOfWeekCubit(this._repo) : super(const TeamOfWeekState());

  final WeekRepository _repo;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const TeamOfWeekState(status: TeamOfWeekStatus.ready, week: 1));
      return;
    }
    emit(const TeamOfWeekState(status: TeamOfWeekStatus.loading));
    try {
      final week = await _repo.latestWeek();
      final players = await _repo.topPlayers(week);
      emit(TeamOfWeekState(status: TeamOfWeekStatus.ready, week: week, players: players));
    } catch (_) {
      emit(const TeamOfWeekState(status: TeamOfWeekStatus.ready, week: 1));
    }
  }

  Future<void> setWeek(int week) async {
    if (week < 1) return;
    emit(TeamOfWeekState(status: TeamOfWeekStatus.loading, week: week));
    try {
      final players = await _repo.topPlayers(week);
      emit(TeamOfWeekState(status: TeamOfWeekStatus.ready, week: week, players: players));
    } catch (_) {
      emit(TeamOfWeekState(status: TeamOfWeekStatus.ready, week: week));
    }
  }
}
