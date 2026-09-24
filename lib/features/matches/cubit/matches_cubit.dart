import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/matches_repository.dart';
import '../data/models/game_match.dart';

part 'matches_state.dart';

/// ViewModel للماتشات القادمة + آخر النتايج. بيتحدّث لوحده لما المدير يغيّر أي ماتش.
class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit(this._repo) : super(const MatchesState());

  final MatchesRepository _repo;
  StreamSubscription<void>? _sub;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const MatchesState(status: MatchesStatus.loaded));
      return;
    }
    emit(const MatchesState(status: MatchesStatus.loading));
    await _fetch();
    _sub ??= liveTable('matches', _fetch);
  }

  Future<void> _fetch() async {
    try {
      final matches = await _repo.fetchUpcoming();
      final results = await _repo.fetchFinished();
      if (isClosed) return;
      emit(MatchesState(
        status: MatchesStatus.loaded,
        matches: matches,
        results: results.take(10).toList(),
      ));
    } catch (_) {
      if (!isClosed && state.isLoading) emit(const MatchesState(status: MatchesStatus.loaded));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
