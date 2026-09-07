import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../squad/data/profile_repository.dart';
import '../../week/data/models/week_player.dart';
import '../../week/data/week_repository.dart';

part 'home_state.dart';

/// ViewModel للرئيسية: نقاط اليوزر + الماتش القادم + أبرز نجوم الجولة.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._profiles, this._matches, this._week) : super(const HomeState());

  final ProfileRepository _profiles;
  final MatchesRepository _matches;
  final WeekRepository _week;

  Future<void> load(String? userId) async {
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const HomeState(status: HomeStatus.ready, points: 0));
      return;
    }
    emit(const HomeState(status: HomeStatus.loading));
    try {
      final profile = await _profiles.fetchProfile(userId);
      final upcoming = await _matches.fetchUpcoming();
      final week = await _week.latestWeek();
      final top = await _week.topPlayers(week);
      emit(HomeState(
        status: HomeStatus.ready,
        points: profile?.totalPoints ?? 0,
        nextMatch: upcoming.isEmpty ? null : upcoming.first,
        topPlayers: top.take(3).toList(),
      ));
    } catch (_) {
      emit(const HomeState(status: HomeStatus.ready));
    }
  }
}
