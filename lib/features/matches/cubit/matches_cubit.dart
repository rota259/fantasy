import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../follow/data/follows_repository.dart';
import '../data/matches_repository.dart';
import '../data/models/game_match.dart';

part 'matches_state.dart';

/// ViewModel للماتشات القادمة + آخر النتايج + الماتشات اللي بتابعها لايف.
/// بيتحدّث لوحده لما المدير يغيّر أي ماتش.
class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit(this._repo, this._follows, this.userId) : super(const MatchesState());

  final MatchesRepository _repo;
  final FollowsRepository _follows;
  final String? userId;
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
      final (matches, results, follows) = await (
        _repo.fetchUpcoming(),
        _repo.fetchFinished(),
        userId == null ? Future.value(<String>{}) : _follows.mine(userId!),
      ).wait;
      if (isClosed) return;
      emit(
        MatchesState(
          status: MatchesStatus.loaded,
          matches: matches,
          results: results.take(10).toList(),
          follows: follows,
        ),
      );
    } catch (_) {
      if (!isClosed && state.isLoading) emit(const MatchesState(status: MatchesStatus.loaded));
    }
  }

  /// الزرار غيّر المتابعة (بعد ما السيرفر وافق).
  void setFollow(String matchId, bool on) {
    final f = {...state.follows};
    on ? f.add(matchId) : f.remove(matchId);
    emit(state.copyWith(follows: f));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
