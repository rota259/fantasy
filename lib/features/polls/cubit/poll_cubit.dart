import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/models/poll.dart';
import '../data/polls_repository.dart';

part 'poll_state.dart';

/// ViewModel لعرض تصويت (نجم/تحدّي) والتصويت فيه.
/// النتايج بتتحدّث لحظيًا، وكمان لما المدير يقفل التصويت أو ينزّل واحد جديد.
class PollCubit extends Cubit<PollState> {
  PollCubit(this._repo, this.kind, this.userId) : super(const PollState());

  final PollsRepository _repo;
  final String kind;
  final String? userId;
  StreamSubscription<void>? _votesSub;
  StreamSubscription<void>? _pollsSub;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const PollState(status: PollStatus.ready));
      return;
    }
    emit(const PollState(status: PollStatus.loading));
    await _fetch();
    _votesSub ??= liveTable('poll_votes', _fetch, primaryKey: const ['poll_id', 'user_id']);
    _pollsSub ??= liveTable('polls', _fetch);
  }

  Future<void> _fetch() async {
    try {
      final view = await _repo.latestPoll(kind, userId!);
      if (!isClosed) emit(PollState(status: PollStatus.ready, view: view));
    } catch (_) {
      if (!isClosed && state.isLoading) emit(const PollState(status: PollStatus.ready));
    }
  }

  Future<void> vote(String optionId) async {
    final v = state.view;
    if (v == null || userId == null || !v.poll.active) return;
    try {
      await _repo.vote(v.poll.id, optionId, userId!);
      await _fetch();
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _votesSub?.cancel();
    _pollsSub?.cancel();
    return super.close();
  }
}
