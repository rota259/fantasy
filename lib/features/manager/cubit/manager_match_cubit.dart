import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/models/match_event.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../data/lineup_repository.dart';

part 'manager_match_state.dart';

/// ViewModel لصفحة إدارة ماتش (المدير يدخّل التشكيلة والأحداث).
class ManagerMatchCubit extends Cubit<ManagerMatchState> {
  ManagerMatchCubit(this._players, this._events, this._lineups, this.match)
      : super(const ManagerMatchState());

  final PlayersRepository _players;
  final EventsRepository _events;
  final LineupRepository _lineups;
  final GameMatch match;

  Future<void> load() async {
    emit(const ManagerMatchState(status: ManagerMatchStatus.loading));
    try {
      final players = await _players.fetchByTeams(match.teams);
      final events = await _events.fetchByMatch(match.id);
      final lineup = await _lineups.fetchForMatch(match.id);
      emit(ManagerMatchState(
        status: ManagerMatchStatus.ready,
        players: players,
        events: events,
        lineup: {for (final l in lineup) l.playerId: l.status},
      ));
    } catch (_) {
      emit(const ManagerMatchState(status: ManagerMatchStatus.ready));
    }
  }

  /// (مدير) إبلاغ كل اليوزرز إن التشكيلة نزلت (عبر Edge Function).
  Future<String> notifyUsers() async {
    try {
      await SupabaseService.client.functions.invoke('notify-match', body: {'match_id': match.id});
      return 'اتبعت إشعار لليوزرز ✓';
    } catch (_) {
      return 'تعذّر إرسال الإشعار';
    }
  }

  /// (مدير) إضافة لاعب لفريق في الماتش وضمّه للتشكيلة كأساسي.
  Future<void> addPlayerToTeam(String name, String team, String position) async {
    final id = await _players.addPlayer(name: name, team: team, position: position);
    await _lineups.setStatus(match.id, id, 'starting');
    await load();
  }

  /// تحديد حالة لاعب في التشكيلة (starting | bench | out).
  Future<void> setLineup(String playerId, String status) async {
    final map = Map<String, String>.from(state.lineup);
    if (status == 'out') {
      await _lineups.remove(match.id, playerId);
      map.remove(playerId);
    } else {
      await _lineups.setStatus(match.id, playerId, status);
      map[playerId] = status;
    }
    emit(state.copyWith(lineup: map));
  }

  Future<void> addEvent(String playerId, String type, int? minute) async {
    await _events.addEvent(matchId: match.id, playerId: playerId, type: type, minute: minute);
    await _reloadEvents();
  }

  Future<void> removeEvent(String id) async {
    await _events.deleteEvent(id);
    await _reloadEvents();
  }

  Future<void> _reloadEvents() async {
    final events = await _events.fetchByMatch(match.id);
    emit(state.copyWith(events: events));
  }

  String playerName(String id) {
    for (final p in state.players) {
      if (p.id == id) return p.name;
    }
    return '—';
  }
}
