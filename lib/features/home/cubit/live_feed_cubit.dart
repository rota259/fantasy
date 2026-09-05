import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../events/data/events_repository.dart';
import '../../players/data/models/player.dart';
import '../../points/points_engine.dart';

part 'live_feed_state.dart';

/// صف في البث الحي.
class FeedEvent {
  const FeedEvent(this.min, this.ini, this.who, this.act, this.pts);
  final String min;
  final String ini;
  final String who;
  final String act;
  final int pts;
}

/// البث الحي ونقاط الجولة. demo = أنيميشن ثابت، live = أحداث حقيقية بالمحرك.
class LiveFeedCubit extends Cubit<LiveFeedState> {
  LiveFeedCubit() : super(const LiveFeedState(count: 0, points: 0));

  static const int _base = 33;
  static const List<FeedEvent> _mock = [
    FeedEvent("12'", 'كر', 'كريم', 'تمريرة حاسمة · Assist', 3),
    FeedEvent("23'", 'آد', 'آدم', 'جوووول · Goal', 5),
    FeedEvent("31'", 'حس', 'حسام', 'شباك نظيفة · Clean sheet', 4),
    FeedEvent("44'", 'عم', 'عمر (C)', 'جوووول ×2 · Captain', 7),
    FeedEvent("58'", 'كر', 'كريم', 'تصدّي مهم · Save', 2),
  ];

  Timer? _timer;

  /// وضع demo: يكشف الصفوف واحدًا تلو الآخر ويجمع من 33.
  void startDemo() {
    _timer?.cancel();
    emit(const LiveFeedState(count: 0, points: _base, events: _mock));
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (state.count >= _mock.length) {
        _timer?.cancel();
        return;
      }
      final next = state.count;
      emit(LiveFeedState(
        count: next + 1,
        points: state.points + _mock[next].pts,
        events: _mock,
      ));
    });
  }

  /// وضع live: يجيب أحداث التشكيلة، يحسب النقاط بالمحرك (الكابتن ×2).
  Future<void> loadLive(List<Player> squad, String? captainId, EventsRepository repo) async {
    _timer?.cancel();
    if (squad.isEmpty) {
      emit(const LiveFeedState(count: 0, points: 0));
      return;
    }
    try {
      final byId = {for (final p in squad) p.id: p};
      final raw = await repo.fetchForPlayers(squad.map((p) => p.id).toList());
      final feed = <FeedEvent>[];
      var total = 0;
      for (final e in raw) {
        final p = byId[e.playerId];
        if (p == null) continue;
        final isCap = e.playerId == captainId;
        final pts = PointsEngine.eventPoints(e.type, p.position) * (isCap ? 2 : 1);
        total += pts;
        feed.add(FeedEvent(
          e.minute != null ? "${e.minute}'" : '',
          p.initials,
          isCap ? '${p.name} (C)' : p.name,
          PointsEngine.eventLabel(e.type),
          pts,
        ));
      }
      emit(LiveFeedState(count: feed.length, points: total, events: feed));
    } catch (_) {
      emit(const LiveFeedState(count: 0, points: 0));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
