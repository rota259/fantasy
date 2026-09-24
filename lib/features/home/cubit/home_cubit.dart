import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/live.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../squad/data/profile_repository.dart';
import '../../week/data/models/week_player.dart';
import '../../week/data/week_repository.dart';
import '../../week/data/week_window.dart';

part 'home_state.dart';

/// ViewModel للرئيسية: نقاط اليوزر + الماتش القادم + أبرز نجوم الجولة.
/// بيتحدّث فورًا (realtime) لما المدير يضيف/يغيّر ماتش.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._profiles, this._matches, this._week) : super(const HomeState());

  final ProfileRepository _profiles;
  final MatchesRepository _matches;
  final WeekRepository _week;

  String? _userId;
  StreamSubscription<void>? _sub;
  StreamSubscription<void>? _eventsSub;

  Future<void> load(String? userId) async {
    _userId = userId;
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const HomeState(status: HomeStatus.ready, points: 0));
      return;
    }
    emit(const HomeState(status: HomeStatus.loading));
    await _fetch();
    _watch();
  }

  /// الاشتراك في تغييرات الماتشات والأحداث — الهوم بيتحدّث (ماتش جاي + نقاط + نجوم) بدون ريفريش.
  void _watch() {
    _sub ??= liveTable('matches', _fetch);
    _eventsSub ??= liveTable('events', _fetch);
    // الوقت نفسه بيغيّر الحالة (الجمعة 4 الفجر → نهائي، السبت → جولة جديدة، نص الليل → يوم جديد)
    _clock ??= Timer.periodic(const Duration(minutes: 1), (_) {
      final win = WeekWindow.current();
      final shown = _shown;
      if (shown == null ||
          shown.$1 != win ||
          shown.$2 != todayRange().from ||
          state.weekFinal != win.isFinal()) {
        _fetch();
      }
    });
  }

  Timer? _clock;
  (WeekWindow, DateTime)? _shown;

  Future<void> _fetch() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final profile = await _profiles.fetchProfile(userId);
      final upcoming = await _matches.fetchUpcoming();
      final win = WeekWindow.current();
      final day = todayRange();
      final week = await _week.pointsBetween(win.start, win.cutoff);
      final today = await _week.pointsBetween(day.from, day.to);
      if (isClosed) return;
      _shown = (win, day.from);
      emit(HomeState(
        status: HomeStatus.ready,
        points: profile?.totalPoints ?? 0,
        nextMatch: upcoming.isEmpty ? null : upcoming.first,
        topPlayers: week.take(5).toList(),
        todayPlayers: today.take(5).toList(),
        weekFinal: win.isFinal(),
        weekLabel: win.label,
      ));
    } catch (_) {
      if (state.isLoading) emit(const HomeState(status: HomeStatus.ready));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _eventsSub?.cancel();
    _clock?.cancel();
    return super.close();
  }
}
