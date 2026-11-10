import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_mode.dart';
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

  /// بتفتح على الجولة اللي خلصت (نهائية) — والتاب التاني الجولة الحالية لايف.
  Future<WeekWindow> _startWindow() async => kTestMode ? WeekWindow.current() : WeekWindow.current().previous;

  /// الجولة الحالية: أعلى ٥ لحد دلوقتي من الماتشات المعتمدة (بتتغيّر لحد ما الجولة تخلص).
  void showLive() => _fetch(WeekWindow.current(), loading: true);

  /// آخر جولة خلصت (نهائية — مبتتغيّرش).
  void showFinished() => _fetch(WeekWindow.current().previous, loading: true);

  void previous() => _fetch(state.window.previous, loading: true);

  void next() {
    if (!state.isCurrent) _fetch(state.window.next, loading: true);
  }

  Future<void> _fetch(WeekWindow w, {bool loading = false}) async {
    if (loading) emit(TeamOfWeekState(window: w));
    try {
      // أعلى ٥ من الماتشات المعتمدة (حارس + ٤) — أول ما ماتش يتعتمد واحد جاب أكتر بياخد المكان
      final ranking = await _repo.approvedPointsBetween(w.start, w.cutoff);
      final top = TeamOfWeek.top5(ranking);
      final published = top.isEmpty ? null : top;
      const PollView? tie = null;
      const tied = <WeekPlayer>[];
      const slots = 0;
      if (!isClosed && state.window == w) {
        emit(
          TeamOfWeekState(
            window: w,
            status: TeamOfWeekStatus.ready,
            published: published,
            ranking: ranking,
            fetchedAt: DateTime.now(),
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
