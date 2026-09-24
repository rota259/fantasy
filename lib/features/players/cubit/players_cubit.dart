import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/models/player.dart';
import '../data/players_repository.dart';

part 'players_state.dart';

/// ViewModel لقائمة اللاعيبة. بيتحدّث لوحده لما المدير يضيف/يعدّل لاعب أو حالته أو نقاطه.
class PlayersCubit extends Cubit<PlayersState> {
  PlayersCubit(this._repo) : super(const PlayersState());

  final PlayersRepository _repo;
  StreamSubscription<void>? _sub;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const PlayersState(status: PlayersStatus.loaded));
      return;
    }
    emit(const PlayersState(status: PlayersStatus.loading));
    await _fetch();
    _sub ??= liveTable('players', _fetch);
  }

  Future<void> _fetch() async {
    try {
      final players = await _repo.fetchAll();
      if (!isClosed) emit(PlayersState(status: PlayersStatus.loaded, players: players));
    } catch (e) {
      if (!isClosed && state.players.isEmpty) {
        emit(PlayersState(status: PlayersStatus.error, message: 'تعذّر تحميل اللاعيبة'));
      }
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
