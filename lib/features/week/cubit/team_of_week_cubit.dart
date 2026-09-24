import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/models/week_player.dart';
import '../data/week_repository.dart';
import '../data/week_window.dart';

part 'team_of_week_state.dart';

/// ViewModel لتشكيلة الأسبوع بالجولة بالوقت:
/// مباشر لحد الجمعة 4 الفجر (بتتغيّر مع كل نقطة)، بعدها نهائي لحد السبت.
class TeamOfWeekCubit extends Cubit<TeamOfWeekState> {
  TeamOfWeekCubit(this._repo) : super(TeamOfWeekState(window: WeekWindow.current()));

  final WeekRepository _repo;
  StreamSubscription<void>? _sub;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(state.copyWith(status: TeamOfWeekStatus.ready));
      return;
    }
    await _fetch(state.window, loading: true);
    // نقطة جديدة → التشكيلة تتحدّث (لو بنعرض الجولة الحالية)
    _sub ??= liveTable('events', () {
      if (state.isCurrent) _fetch(state.window);
    });
  }

  void previous() => _fetch(state.window.previous, loading: true);

  void next() {
    if (!state.isCurrent) _fetch(state.window.next, loading: true);
  }

  Future<void> _fetch(WeekWindow w, {bool loading = false}) async {
    if (loading) emit(TeamOfWeekState(window: w));
    try {
      final players = await _repo.pointsBetween(w.start, w.cutoff);
      if (!isClosed && state.window == w) {
        emit(TeamOfWeekState(window: w, status: TeamOfWeekStatus.ready, players: players));
      }
    } catch (_) {
      if (!isClosed && state.window == w) emit(state.copyWith(status: TeamOfWeekStatus.ready));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
