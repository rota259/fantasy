import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../data/matches_repository.dart';
import '../data/models/game_match.dart';

part 'matches_state.dart';

/// ViewModel للماتشات القادمة. في وضع demo بيرجّع فاضي فالشاشة تستخدم الـ mock.
class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit(this._repo) : super(const MatchesState());

  final MatchesRepository _repo;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const MatchesState(status: MatchesStatus.loaded));
      return;
    }
    emit(const MatchesState(status: MatchesStatus.loading));
    try {
      final matches = await _repo.fetchUpcoming();
      emit(MatchesState(status: MatchesStatus.loaded, matches: matches));
    } catch (_) {
      emit(const MatchesState(status: MatchesStatus.loaded));
    }
  }
}
