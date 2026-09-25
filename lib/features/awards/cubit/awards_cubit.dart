import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/live.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../polls/data/models/poll.dart';
import '../../polls/data/polls_repository.dart';
import '../../../core/utils/perf.dart';

part 'awards_state.dart';

/// ViewModel هدف وتصدّي الجولة (والموسم لو المدير عمله).
/// الصوت بيظهر فورًا (قبل ما السيرفر يرد)، والنتايج اللحظية بتتجمّع كل ثانيتين عشان الشاشة متعلّقش.
class AwardsCubit extends Cubit<AwardsState> {
  AwardsCubit(this._repo, this.userId) : super(const AwardsState());

  final PollsRepository _repo;
  final String? userId;
  StreamSubscription<void>? _votesSub;
  StreamSubscription<void>? _pollsSub;
  Timer? _debounce;

  static const kinds = [PollKind.goalWeek, PollKind.saveWeek, PollKind.goalSeason, PollKind.saveSeason];

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const AwardsState(loading: false));
      return;
    }
    await timed('awards', _fetchAll);
    _votesSub ??= liveTable('poll_votes', _scheduleRefresh);
    _pollsSub ??= liveTable('polls', _scheduleRefresh);
  }

  /// أصوات الناس بتيجي كتير ورا بعض — نحدّث مرة واحدة بعد ما تهدى.
  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _fetchAll);
  }

  Future<void> _fetchAll() async {
    try {
      final views = await Future.wait([for (final k in kinds) _repo.latestPoll(k, userId!)]);
      if (isClosed) return;
      emit(
        AwardsState(
          loading: false,
          polls: {
            for (var i = 0; i < kinds.length; i++)
              if (views[i] != null) kinds[i]: views[i]!,
          },
        ),
      );
    } catch (_) {
      if (!isClosed && state.loading) emit(const AwardsState(loading: false));
    }
  }

  /// بيرجّع رسالة خطأ أو null.
  Future<String?> vote(String kind, String optionId) async {
    final v = state.polls[kind];
    if (v == null || userId == null || state.busy) return null;
    if (!v.poll.open) return 'التصويت اتقفل';
    emit(state.copyWith(polls: {...state.polls, kind: _withMyVote(v, optionId)}, busy: true));
    try {
      await _repo.vote(v.poll.id, optionId, userId!);
      final fresh = await _repo.latestPoll(kind, userId!);
      if (!isClosed) emit(state.copyWith(polls: {...state.polls, if (fresh != null) kind: fresh}, busy: false));
      return null;
    } catch (e) {
      if (!isClosed) emit(state.copyWith(polls: {...state.polls, kind: v}, busy: false)); // نرجّع زي ما كان
      return dbMessage(e, fallback: 'تعذّر التصويت — جرّب تاني');
    }
  }

  /// النتيجة المتوقعة بعد صوتي (قبل رد السيرفر).
  static PollView _withMyVote(PollView v, String optionId) => PollView(
    poll: v.poll,
    options: [
      for (final o in v.options)
        o.copyWith(
          votes: o.votes + (o.id == optionId && !o.mine ? 1 : 0) - (o.mine && o.id != optionId ? 1 : 0),
          mine: o.id == optionId,
        ),
    ],
  );

  @override
  Future<void> close() {
    _votesSub?.cancel();
    _pollsSub?.cancel();
    _debounce?.cancel();
    return super.close();
  }
}
