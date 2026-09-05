import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../coach_engine.dart';

part 'coach_state.dart';

/// ViewModel لمدرّب الذكاء — بيحسب توصية من التشكيلة + السوق.
class CoachCubit extends Cubit<CoachState> {
  CoachCubit(this._players) : super(const CoachState());

  final PlayersRepository _players;

  Future<void> load(List<Player> squad, double remaining) async {
    if (!SupabaseConfig.isConfigured) {
      emit(const CoachState(status: CoachStatus.loaded));
      return;
    }
    emit(const CoachState(status: CoachStatus.loading));
    try {
      final market = await _players.fetchAll();
      final advice = CoachEngine.recommend(squad, market, remaining);
      emit(CoachState(status: CoachStatus.loaded, advice: advice));
    } catch (_) {
      emit(const CoachState(status: CoachStatus.loaded));
    }
  }
}
