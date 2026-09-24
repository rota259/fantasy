import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/models/match_event.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../points/points_engine.dart';
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

  /// (مدير) إبلاغ كل اليوزرز إن التشكيلة نزلت.
  /// بيسجّل الإشعار في الجدول (يظهر جوه التطبيق) + يبعت push عبر Edge Function.
  Future<String> notifyUsers() async {
    final title = 'تشكيلة نزلت ⚽';
    final body = '${match.teamA} ضد ${match.teamB} — اختار تشكيلتك قبل الديدلاين';
    await _record(title, body, 'lineup');
    try {
      await SupabaseService.client.functions.invoke('notify-match', body: {'match_id': match.id});
      return 'اتبعت إشعار لليوزرز ✓';
    } catch (_) {
      return 'اتسجّل الإشعار جوه التطبيق (الـ push لسه مش مفعّل)';
    }
  }

  /// تسجيل إشعار في جدول notifications عشان يظهر لليوزرز جوه التطبيق.
  Future<void> _record(String title, String body, String kind) async {
    try {
      await SupabaseService.table('notifications')
          .insert({'title': title, 'body': body, 'kind': kind, 'match_id': match.id});
    } catch (_) {}
  }

  /// (مدير) إضافة لاعب لفريق في الماتش (بيظهر بره لحد ما المدير يحطّه أساسي/احتياطي).
  Future<void> addPlayerToTeam(String name, String team, String position) async {
    await _players.addPlayer(name: name, team: team, position: position);
    final players = await _players.fetchByTeams(match.teams);
    emit(state.copyWith(players: players));
  }

  /// تحديد حالة لاعب في التشكيلة محليًا (starting | bench | out) مع حدود الفريق.
  /// بيرجّع رسالة خطأ لو تعدّى الحد، أو null لو تمام.
  String? setLineup(String playerId, String status) {
    final map = Map<String, String>.from(state.lineup);
    if (status == 'out') {
      map.remove(playerId);
    } else {
      final err = _capError(playerId, status);
      if (err != null) return err;
      map[playerId] = status;
    }
    emit(state.copyWith(lineup: map));
    return null;
  }

  /// الحدود: ٤ لاعيبة + حارس أساسيين + ٢ احتياطي لكل فريق.
  String? _capError(String playerId, String status) {
    final p = _player(playerId);
    if (p == null) return null;
    int countIn(String st, bool Function(Player) test) {
      var n = 0;
      state.lineup.forEach((id, s) {
        if (s == st && id != playerId) {
          final q = _player(id);
          if (q != null && q.team == p.team && test(q)) n++;
        }
      });
      return n;
    }

    if (status == 'starting') {
      if (p.position == 'GK') {
        if (countIn('starting', (q) => q.position == 'GK') >= 1) {
          return 'فيه حارس أساسي بالفعل في ${p.team}';
        }
      } else if (countIn('starting', (q) => q.position != 'GK') >= 4) {
        return 'كمّلت ٤ لاعيبة أساسيين في ${p.team}';
      }
    } else if (countIn('bench', (_) => true) >= 2) {
      return 'كمّلت ٢ احتياطي في ${p.team}';
    }
    return null;
  }

  /// (مدير) حفظ التشكيلة كاملة — لازم كل فريق: ٥ أساسي (منهم حارس) + ٢ احتياطي.
  Future<String> saveLineup() async {
    final err = _validateLineup();
    if (err != null) return err;
    try {
      await _lineups.replaceForMatch(match.id, state.lineup);
      return 'اتحفظت التشكيلة ✓';
    } catch (e) {
      return 'فشل الحفظ: $e';
    }
  }

  /// التحقّق: كل فريق لازم يبقى فيه ٥ أساسي بالظبط (حارس + ٤) + ٢ احتياطي بالظبط.
  String? _validateLineup() {
    for (final team in match.teams) {
      var start = 0, gk = 0, bench = 0;
      state.lineup.forEach((id, st) {
        final p = _player(id);
        if (p == null || p.team != team) return;
        if (st == 'starting') {
          start++;
          if (p.position == 'GK') gk++;
        } else if (st == 'bench') {
          bench++;
        }
      });
      if (start != 5) return 'لازم ٥ أساسيين بالظبط في $team (دلوقتي $start)';
      if (gk != 1) return 'لازم حارس أساسي واحد في $team';
      if (bench != 2) return 'لازم ٢ احتياطي بالظبط في $team (دلوقتي $bench)';
    }
    return null;
  }

  Player? _player(String id) {
    for (final p in state.players) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// بيرجّع null لو اتسجّل، أو رسالة الخطأ.
  Future<String?> addEvent(String playerId, String type, int? minute) async {
    try {
      await _events.addEvent(matchId: match.id, playerId: playerId, type: type, minute: minute);
    } catch (e) {
      return 'تعذّر تسجيل الحدث: $e';
    }
    await _reloadEvents();
    _notifyEvent(playerId, type); // إشعار لكل اليوزرز بالحدث
    return null;
  }

  /// إشعار بكل حدث بيتضاف (goal/assist/…) — في التطبيق + push.
  Future<void> _notifyEvent(String playerId, String type) async {
    final title = '${PointsEngine.eventLabel(type)} ⚽';
    final body = '${playerName(playerId)} · ${match.teamA} ضد ${match.teamB}';
    await _record(title, body, 'event');
    try {
      await SupabaseService.client.functions.invoke('notify-match', body: {
        'match_id': match.id,
        'title': title,
        'body': body,
      });
    } catch (_) {}
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
