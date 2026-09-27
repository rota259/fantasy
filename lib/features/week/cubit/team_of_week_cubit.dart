import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/live_hub.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../polls/data/models/poll.dart';
import '../../polls/data/polls_repository.dart';
import '../data/models/week_player.dart';
import '../data/team_of_week.dart';
import '../data/week_repository.dart';
import '../data/week_window.dart';
import '../../../core/utils/perf.dart';

part 'team_of_week_state.dart';

/// ViewModel تشكيلة الجولة: مش لايف — بتظهر بعد ما الجولة تخلص (السبت ٨ الصبح) والإدارة تعتمدها لمنطقتي،
/// وبتفضل هي اللي بتفتح لحد ما تشكيلة الجولة اللي بعدها تتعتمد.
/// ولو فيه تعادل على آخر مكان → اليوزرز بيصوّتوا (لحد نص الليل) قبل الاعتماد.
class TeamOfWeekCubit extends Cubit<TeamOfWeekState> {
  TeamOfWeekCubit(this._repo, this._polls, this.userId) : super(TeamOfWeekState(window: WeekWindow.current()));

  final WeekRepository _repo;
  final PollsRepository _polls;
  final String? userId;
  Timer? _votesTimer;
  StreamSubscription<void>? _notifySub; // نتايج تصويت التعادل كل ٣٠ ثانية

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(state.copyWith(status: TeamOfWeekStatus.ready));
      return;
    }
    await timed('team of week', () async => _fetch(await _startWindow(), loading: true));
    // الإدارة اعتمدت التشكيلة → إشعار "نزلت" بيحدّث الشاشة
    _notifySub ??= LiveHub.on('notify', () => _fetch(state.window));
    _votesTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.tie?.poll.open ?? false) _fetch(state.window);
    });
  }

  /// آخر جولة خلصت — ولو لسه مااتعتمدتش ومفيش تصويت تعادل فيها، آخر واحدة اتعتمدت.
  Future<WeekWindow> _startWindow() async {
    final last = WeekWindow.current().previous;
    try {
      final published = await _repo.latestPublishedRound();
      if (published == null || published == last) return last;
      final tie = userId == null ? null : await _polls.tieFor(last.cutoff, userId!);
      return tie != null ? last : published;
    } catch (_) {
      return last;
    }
  }

  void previous() => _fetch(state.window.previous, loading: true);

  void next() {
    if (!state.isCurrent) _fetch(state.window.next, loading: true);
  }

  Future<void> _fetch(WeekWindow w, {bool loading = false}) async {
    if (loading) emit(TeamOfWeekState(window: w));
    try {
      final published = await _repo.publishedTeam(w);
      var ranking = const <WeekPlayer>[];
      PollView? tie;
      var tied = const <WeekPlayer>[];
      var slots = 0;
      if (published != null) {
        ranking = await _repo.pointsBetween(w.start, w.cutoff); // الترتيب الكامل بعد الاعتماد بس
      } else if (w.isFinal() && userId != null) {
        // الجولة خلصت ولسه مستنية الإدارة — لو فيه تعادل، اليوزرز بيصوّتوا
        tie = await _polls.tieFor(w.cutoff, userId!);
        if (tie != null) {
          final team = TeamOfWeek.build(await _repo.pointsBetween(w.start, w.cutoff));
          tied = team.tied;
          slots = team.openSlots;
        }
      }
      if (!isClosed && state.window == w) {
        emit(
          TeamOfWeekState(
            window: w,
            status: TeamOfWeekStatus.ready,
            published: published,
            ranking: ranking,
            tie: tie,
            tied: tied,
            slots: slots,
          ),
        );
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
    _votesTimer?.cancel();
    _notifySub?.cancel();
    return super.close();
  }
}
