import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:fantasy_5omasi/repositories/league_repository.dart';

part 'league_state.dart';

class LeagueCubit extends Cubit<LeagueState> {
  final LeagueRepository leagueRepository;
  final String leagueId;

  LeagueCubit(this.leagueRepository, this.leagueId) : super(LeagueInitial());

  Future<void> fetchLeagueMembers() async {
    emit(LeagueLoading());
    try {
      final members = await leagueRepository.getLeagueMembers(leagueId);
      emit(LeagueLoaded(members));
    } catch (e) {
      emit(LeagueError(e.toString()));
    }
  }

  Future<void> joinLeague(String userId) async {
    emit(LeagueLoading());
    try {
      await leagueRepository.addUserToLeague(leagueId, userId);
      await fetchLeagueMembers();
    } catch (e) {
      emit(LeagueError(e.toString()));
    }
  }
}
