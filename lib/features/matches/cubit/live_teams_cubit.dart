import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live_hub.dart';
import '../../week/data/week_window.dart';
import '../data/matches_repository.dart';
import '../data/models/game_match.dart';
import '../match_live.dart';

/// الفرق اللي بتلعب ماتش دلوقتي في جولة — عشان لاعيبتها تنوّر في التشكيلة وقت الماتش بس.
/// بيتحدّث مع كل تغيير في الماتشات، وكل دقيقة (ماتش بدأ ميعاده).
class LiveTeamsCubit extends Cubit<Set<String>> {
  LiveTeamsCubit(this._matches, this.window) : super(const {});

  final MatchesRepository _matches;
  final WeekWindow window;
  List<GameMatch> _list = const [];
  StreamSubscription<void>? _sub;
  Timer? _clock;

  Future<void> load() async {
    await _fetch();
    _sub ??= LiveHub.on('matches', _fetch);
    _clock ??= Timer.periodic(const Duration(minutes: 1), (_) => _emit());
  }

  Future<void> _fetch() async {
    try {
      _list = await _matches.fetchInWindow(window.start, window.cutoff);
      _emit();
    } catch (_) {}
  }

  void _emit() {
    if (!isClosed) emit(MatchLive.liveTeams(_list));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _clock?.cancel();
    return super.close();
  }
}
