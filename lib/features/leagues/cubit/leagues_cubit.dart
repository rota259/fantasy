import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../data/leagues_repository.dart';
import '../data/models/league_standing.dart';

part 'leagues_state.dart';

/// ViewModel للدوريات: الترتيب العام + دورياتي + جدول الترتيب.
class LeaguesCubit extends Cubit<LeaguesState> {
  LeaguesCubit(this._repo) : super(const LeaguesState());

  final LeaguesRepository _repo;
  String? _userId;

  Future<void> load(String? userId) async {
    _userId = userId;
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const LeaguesState(status: LeaguesStatus.loaded));
      return;
    }
    emit(const LeaguesState(status: LeaguesStatus.loading));
    try {
      final rank = await _repo.globalRank(userId);
      final leagues = await _repo.myLeagues(userId);
      final firstId = leagues.isNotEmpty ? leagues.first.league.id : null;
      final table = firstId != null ? await _repo.standings(firstId) : <LeagueStanding>[];
      emit(LeaguesState(
        status: LeaguesStatus.loaded,
        globalRank: rank,
        myLeagues: leagues,
        standings: table,
        selectedLeagueId: firstId,
      ));
    } catch (_) {
      emit(const LeaguesState(status: LeaguesStatus.loaded));
    }
  }

  Future<void> selectLeague(String leagueId) async {
    emit(state.copyWith(selectedLeagueId: leagueId));
    try {
      final table = await _repo.standings(leagueId);
      emit(state.copyWith(standings: table));
    } catch (_) {}
  }

  Future<String> join(String inviteCode) async {
    if (_userId == null) return 'سجّل دخولك الأول';
    try {
      await _repo.joinByCode(inviteCode.trim(), _userId!);
      await load(_userId);
      return 'اتنضممت للدوري ✓';
    } catch (_) {
      return 'كود غير صحيح';
    }
  }
}
