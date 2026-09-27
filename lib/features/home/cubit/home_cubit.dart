import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live_hub.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../integrity/data/integrity_repository.dart';
import '../../integrity/data/models/pending_review.dart';
import '../../matches/data/matches_repository.dart';
import '../../pick/data/models/pick.dart';
import '../../pick/data/picks_repository.dart';
import '../../matches/data/models/game_match.dart';
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
  HomeCubit(this._profiles, this._matches, this._week, this._polls, this._integrity, this._picks)
    : super(const HomeState());

  final ProfileRepository _profiles;
  final MatchesRepository _matches;
  final WeekRepository _week;
  final PollsRepository _polls;
  final IntegrityRepository _integrity;
  final PicksRepository _picks;

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
    await timed('home', _fetch);
    _matchesSub ??= LiveHub.on('matches', _fetch);
    _eventsSub ??= LiveHub.on('events', _fetch);
    _clock ??= Timer.periodic(const Duration(minutes: 1), (_) {
      final win = WeekWindow.live(); // الجولة اتغيّرت (السبت ٤ العصر) أو خلصت (٨ الصبح)
      if (_shown == null || _shown!.$1 != win || _shown!.$2 != win.isFinal()) _fetch();
    });
  }

  /// بعد ما اليوزر يأكد ورقة ماتش مثلًا.
  Future<void> refresh() => _fetch();

  Future<({WeekWindow window, List<WeekPlayer>? team})?> _latestTeam() async {
    final w = await _week.latestPublishedRound();
    return w == null ? null : (window: w, team: await _week.publishedTeam(w));
  }

  Future<void> _fetch() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final win = WeekWindow.current();
      // كل الطلبات مع بعض (مش ورا بعض) — الوقت = أبطأ طلب بس
      final open = WeekWindow.open();
      final live = WeekWindow.live();
      final (points, upcoming, finished, team, tie, reviews, myRound) = await (
        // نقط الجولة اللي بتتلعب بس (كل جولة من صفر — الإجمالي في البروفايل)
        _profiles.roundPoints(userId, live.cutoff),
        _matches.fetchUpcoming(),
        _matches.fetchFinished(),
        // نجم الجولة = الأعلى في آخر تشكيلة جولة الإدارة اعتمدتها لمنطقتي (بيفضل لحد اللي بعدها)
        _latestTeam().catchError((_) => null),
        // تعادل تشكيلة الجولة اللي لسه خالصة (التصويت مفتوح ٢٠ ساعة بعدها)
        _polls.tieFor(win.previous.cutoff, userId),
        _integrity.myPendingReviews().catchError((_) => const <PendingReview>[]),
        _picks.fetchRound(userId, open.cutoff).catchError((_) => const <Pick>[]),
      ).wait;
      final star = team?.team?.firstOrNull;
      if (isClosed) return;
      _shown = (live, live.isFinal());
      emit(
        HomeState(
          status: HomeStatus.ready,
          points: points,
          nextMatch: upcoming.firstOrNull,
          star: star,
          weekFinal: star != null,
          weekLabel: (team?.window ?? win.previous).label,
          toRate: finished.where((m) => m.ratingOpen).take(3).toList(),
          tieOpen: tie != null && tie.poll.open,
          toReview: reviews,
          openRound: open,
          roundSaved: myRound.isNotEmpty,
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
