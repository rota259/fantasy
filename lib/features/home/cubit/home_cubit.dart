import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/supabase/server_tick.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../polls/data/models/poll.dart';
import '../../polls/data/polls_repository.dart';
import '../../squad/data/profile_repository.dart';
import '../../week/data/models/week_player.dart';
import '../../week/data/week_repository.dart';
import '../../week/data/week_window.dart';
import '../../../core/utils/perf.dart';

part 'home_state.dart';

/// ViewModel للرئيسية: نقاط اليوزر + الماتش القادم + نجم الجولة + التنبيهات.
/// بيتحدّث فورًا (realtime) ومع الوقت (الجمعة 4 الفجر → نهائي، السبت → جولة جديدة).
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._profiles, this._matches, this._week, this._polls) : super(const HomeState());

  final ProfileRepository _profiles;
  final MatchesRepository _matches;
  final WeekRepository _week;
  final PollsRepository _polls;

  String? _userId;
  StreamSubscription<void>? _matchesSub;
  StreamSubscription<void>? _eventsSub;
  Timer? _clock;
  (WeekWindow, bool)? _shown;

  Future<void> load(String? userId) async {
    _userId = userId;
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const HomeState(status: HomeStatus.ready));
      return;
    }
    emit(const HomeState(status: HomeStatus.loading));
    ServerTick.run(); // احتياطي لمهمة السيرفر الدورية
    await timed('home', _fetch);
    _matchesSub ??= liveTable('matches', _fetch);
    _eventsSub ??= liveTable('events', _fetch);
    _clock ??= Timer.periodic(const Duration(minutes: 1), (_) {
      final win = WeekWindow.current();
      if (_shown == null || _shown!.$1 != win || _shown!.$2 != win.isFinal()) _fetch();
      ServerTick.run();
    });
  }

  Future<void> _fetch() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final win = WeekWindow.current();
      // كل الطلبات مع بعض (مش ورا بعض) — الوقت = أبطأ طلب بس
      final (points, upcoming, finished, current, previous, tie) = await (
        _profiles.points(userId),
        _matches.fetchUpcoming(),
        _matches.fetchFinished(),
        _week.pointsBetween(win.start, win.cutoff),
        _week.pointsBetween(win.previous.start, win.previous.cutoff),
        win.isFinal() ? _polls.tieFor(win.cutoff, userId) : Future<PollView?>.value(),
      ).wait;
      final star = current.firstOrNull ?? previous.firstOrNull;
      final fromPrevious = current.isEmpty && star != null;
      if (isClosed) return;
      _shown = (win, win.isFinal());
      emit(
        HomeState(
          status: HomeStatus.ready,
          points: points,
          nextMatch: upcoming.firstOrNull,
          star: star,
          starFromPrevious: fromPrevious,
          weekFinal: win.isFinal(),
          weekLabel: fromPrevious ? win.previous.label : win.label,
          toRate: finished.where((m) => m.ratingOpen).take(3).toList(),
          tieOpen: tie != null && tie.poll.open,
        ),
      );
    } catch (_) {
      if (!isClosed && state.isLoading) emit(const HomeState(status: HomeStatus.ready));
    }
  }

  @override
  Future<void> close() {
    _matchesSub?.cancel();
    _eventsSub?.cancel();
    _clock?.cancel();
    return super.close();
  }
}
