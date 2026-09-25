import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/live.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../polls/data/models/poll.dart';
import '../../polls/data/polls_repository.dart';
import '../data/models/week_player.dart';
import '../data/team_of_week.dart';
import '../data/week_repository.dart';
import '../data/week_window.dart';
import '../../../core/utils/perf.dart';

part 'team_of_week_state.dart';

/// ViewModel تشكيلة الجولة: مباشر لحد الجمعة ٤ الفجر، بعدها نهائي
/// (ولو فيه تعادل على آخر مكان → تصويت لحد نص الليل).
class TeamOfWeekCubit extends Cubit<TeamOfWeekState> {
  TeamOfWeekCubit(this._repo, this._polls, this.userId) : super(TeamOfWeekState(window: WeekWindow.current()));

  final WeekRepository _repo;
  final PollsRepository _polls;
  final String? userId;
  StreamSubscription<void>? _eventsSub;
  StreamSubscription<void>? _votesSub;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(state.copyWith(status: TeamOfWeekStatus.ready));
      return;
    }
    await timed('team of week', () => _fetch(state.window, loading: true));
    _eventsSub ??= liveTable('events', () {
      if (state.isCurrent) _fetch(state.window);
    });
    _votesSub ??= liveTable('poll_votes', () {
      if (state.tie != null) _fetch(state.window);
    });
  }

  void previous() => _fetch(state.window.previous, loading: true);

  void next() {
    if (!state.isCurrent) _fetch(state.window.next, loading: true);
  }

  Future<void> _fetch(WeekWindow w, {bool loading = false}) async {
    if (loading) emit(TeamOfWeekState(window: w));
    try {
      // التعادل بيتحسم بتصويت بس لما الجولة تبقى نهائي
      final (players, tie) = await (
        _repo.pointsBetween(w.start, w.cutoff),
        (w.isFinal() && userId != null) ? _polls.tieFor(w.cutoff, userId!) : Future<PollView?>.value(),
      ).wait;
      if (!isClosed && state.window == w) {
        emit(TeamOfWeekState(window: w, status: TeamOfWeekStatus.ready, players: players, tie: tie));
      }
    } catch (_) {
      if (!isClosed && state.window == w) emit(state.copyWith(status: TeamOfWeekStatus.ready));
    }
  }

  /// صوت في تصويت التعادل. بيرجّع رسالة خطأ أو null.
  Future<String?> voteTie(String optionId) async {
    final t = state.tie;
    if (t == null || userId == null) return null;
    if (!t.poll.open) return 'التصويت اتقفل';
    try {
      await _polls.vote(t.poll.id, optionId, userId!);
      await _fetch(state.window);
      return null;
    } catch (e) {
      return dbMessage(e, fallback: 'تعذّر التصويت');
    }
  }

  @override
  Future<void> close() {
    _eventsSub?.cancel();
    _votesSub?.cancel();
    return super.close();
  }
}
