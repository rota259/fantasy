import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';

part 'manager_players_state.dart';

/// ViewModel لإدارة اللاعيبة (المدير يضيف/يحذف).
class ManagerPlayersCubit extends Cubit<ManagerPlayersState> {
  ManagerPlayersCubit(this._repo) : super(const ManagerPlayersState());

  final PlayersRepository _repo;

  Future<void> load() async {
    emit(const ManagerPlayersState(status: ManagerPlayersStatus.loading));
    try {
      final players = await _repo.fetchAll();
      emit(ManagerPlayersState(status: ManagerPlayersStatus.ready, players: players));
    } catch (_) {
      emit(const ManagerPlayersState(status: ManagerPlayersStatus.ready));
    }
  }

  Future<void> add({
    required String name,
    required String team,
    required String position,
    required double price,
  }) async {
    await _repo.addPlayer(name: name, team: team, position: position, price: price);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.deletePlayer(id);
    await load();
  }
}
