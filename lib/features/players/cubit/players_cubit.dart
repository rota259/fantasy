import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../data/models/player.dart';
import '../data/players_repository.dart';

part 'players_state.dart';

/// ViewModel لقائمة اللاعيبة (السوق). في وضع demo بيرجّع فاضي فالشاشة تستخدم الـ mock.
class PlayersCubit extends Cubit<PlayersState> {
  PlayersCubit(this._repo) : super(const PlayersState());

  final PlayersRepository _repo;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const PlayersState(status: PlayersStatus.loaded));
      return;
    }
    emit(const PlayersState(status: PlayersStatus.loading));
    try {
      final players = await _repo.fetchAll();
      emit(PlayersState(status: PlayersStatus.loaded, players: players));
    } catch (e) {
      emit(PlayersState(status: PlayersStatus.error, message: 'تعذّر تحميل اللاعيبة'));
    }
  }
}
