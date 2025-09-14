import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fantasy_5omasi/models/player_model.dart';
import 'package:fantasy_5omasi/repositories/player_repository.dart';

part 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final PlayerRepository playerRepository;

  PlayerCubit(this.playerRepository) : super(PlayerInitial());

  Future<void> fetchPlayers() async {
    emit(PlayerLoading());
    try {
      final players = await playerRepository.getAllPlayers();
      emit(PlayerLoaded(players));
    } catch (e) {
      emit(PlayerError(e.toString()));
    }
  }

  Future<void> addPlayer(PlayerModel player) async {
    emit(PlayerLoading());
    try {
      await playerRepository.addPlayer(player);
      await fetchPlayers();
    } catch (e) {
      emit(PlayerError(e.toString()));
    }
  }

  Future<void> updatePlayer(PlayerModel player) async {
    emit(PlayerLoading());
    try {
      await playerRepository.updatePlayer(player);
      await fetchPlayers();
    } catch (e) {
      emit(PlayerError(e.toString()));
    }
  }

  Future<void> deletePlayer(String playerId) async {
    emit(PlayerLoading());
    try {
      await playerRepository.deletePlayer(playerId);
      await fetchPlayers();
    } catch (e) {
      emit(PlayerError(e.toString()));
    }
  }
}
