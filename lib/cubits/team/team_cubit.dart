import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fantasy_5omasi/models/player_model.dart';
import 'package:fantasy_5omasi/repositories/team_repository.dart';

part 'team_state.dart';

class TeamCubit extends Cubit<TeamState> {
  final TeamRepository teamRepository;
  final String userId;

  TeamCubit(this.teamRepository, this.userId) : super(TeamInitial());

  Future<void> fetchTeam() async {
    emit(TeamLoading());
    try {
      final team = await teamRepository.getUserTeam(userId);
      emit(TeamLoaded(team));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> updateTeam(List<String> playerIds) async {
    emit(TeamLoading());
    try {
      await teamRepository.updateUserTeam(userId, playerIds);
      await fetchTeam();
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }
}
