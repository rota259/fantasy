import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_mode.dart';
import '../../../core/supabase/db_error.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/models/match_event.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/match_live.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../integrity/data/integrity_repository.dart';
import '../data/lineup_repository.dart';

part 'manager_match_state.dart';

/// ViewModel لصفحة إدارة ماتش (المدير يدخّل التشكيلة والأحداث).
class ManagerMatchCubit extends Cubit<ManagerMatchState> {
  ManagerMatchCubit(this._players, this._events, this._lineups, this._integrity, this.match)
    : super(ManagerMatchState(format: match.format));

  final IntegrityRepository _integrity;
  final PlayersRepository _players;
  final EventsRepository _events;
  final LineupRepository _lineups;
  final GameMatch match;

  Future<void> load() async {
    emit(ManagerMatchState(status: ManagerMatchStatus.loading, format: state.format));
    try {
      final players = await _players.fetchByTeams(match.teams);
      final events = await _events.fetchByMatch(match.id);
      final lineup = await _lineups.fetchForMatch(match.id);
      emit(
        ManagerMatchState(
          status: ManagerMatchStatus.ready,
          players: players,
          events: events,
          lineup: {for (final l in lineup) l.playerId: l.status},
          format: state.format,
        ),
      );
    } catch (_) {
      emit(ManagerMatchState(status: ManagerMatchStatus.ready, format: state.format));
    }
  }

  /// إبلاغ كل اليوزرز إن التشكيلة نزلت (السيرفر بيبعته — المدير مرة واحدة لكل ماتش).
  Future<String> notifyUsers() async {
    try {
      await _integrity.notifyLineup(match.id);
      return 'اتبعت إشعار لليوزرز ✓';
    } catch (e) {
      return dbMessage(e, fallback: 'فشل الإرسال');
    }
  }

  /// إضافة لاعب جديد لفريق في الماتش (بيبقى في الفريق لحد ما المدير يحطّه في التشكيلة).
  Future<void> addPlayerToTeam(String name, String team, String position) async {
    await _players.addPlayer(name: name, team: team, position: position);
    final players = await _players.fetchByTeams(match.teams);
    emit(state.copyWith(players: players));
  }

  /// خماسي (٥) أو سداسي (٦) — بيتحفظ مع التشكيلة.
  void setFormat(int f) => emit(state.copyWith(format: f));

  /// (مدير) حذف لاعب من الفريق خالص (لو لسه ملعبش) — بيرجّع رسالة خطأ أو null.
  Future<String?> deletePlayer(String id) async {
    try {
      final n = await _players.deletePlayers([id]);
      if (n == 0) return 'اللاعب ده لعب واتسجّل له أحداث — شيله من التشكيلة بس، أو كلّم الإدارة';
      final players = await _players.fetchByTeams(match.teams);
      emit(state.copyWith(players: players, lineup: Map.of(state.lineup)..remove(id)));
      return null;
    } catch (e) {
      return dbMessage(e, fallback: 'تعذّر الحذف');
    }
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

  /// الحدود لكل فريق: حارس أساسي واحد + (الملعب − ١) في الملعب · الفريق كله ≤ ٧.
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

    final f = state.format;
    if (countIn('starting', (_) => true) + countIn('bench', (_) => true) >= ManagerMatchState.squadMax) {
      return '${p.team} كمّل ${ManagerMatchState.squadMax} لاعيبة';
    }
    if (status == 'starting') {
      if (p.position == 'GK') {
        if (countIn('starting', (q) => q.position == 'GK') >= 1) {
          return 'فيه حارس أساسي بالفعل في ${p.team}';
        }
      } else if (countIn('starting', (q) => q.position != 'GK') >= f - 1) {
        return 'كمّلت ${f - 1} لاعيبة في الملعب في ${p.team}';
      }
    }
    return null;
  }

  /// (مدير) حفظ التشكيلة كاملة — كل فريق: الأساسي = الملعب بالظبط (منهم حارس) + احتياطي اختياري، والكل ≤ ٧.
  Future<String> saveLineup() async {
    final err = _validateLineup();
    if (err != null) return err;
    try {
      await _lineups.replaceForMatch(match.id, state.lineup, format: state.format);
      return 'اتحفظت التشكيلة ✓';
    } catch (e) {
      return dbMessage(e, fallback: 'فشل الحفظ');
    }
  }

  /// التحقّق: كل فريق — الأساسي = الملعب بالظبط (حارس واحد) · الاحتياطي اختياري · الكل ≤ ٧.
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
      final f = state.format;
      if (start != f) return 'الملعب ${f == 6 ? 'سداسي' : 'خماسي'}: لازم $f أساسيين بالظبط في $team (دلوقتي $start)';
      if (gk != 1) return 'لازم حارس أساسي واحد في $team';
      if (start + bench > ManagerMatchState.squadMax) return 'الفريق آخره ${ManagerMatchState.squadMax} في $team';
    }
    return null;
  }

  Player? _player(String id) {
    for (final p in state.players) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// اللي في الملعب دلوقتي (الأساسيين + اللي نزلوا − اللي طلعوا − الأحمر).
  Set<String> get onPitch => MatchLive.onPitch(state.lineup, state.events);

  /// الاحتياطي اللي لسه منزلش.
  Set<String> get benchLeft => MatchLive.benchLeft(state.lineup, state.events);

  /// النتيجة من الأهداف المسجّلة (نفس السيرفر).
  ({int a, int b}) get score =>
      MatchLive.score(match.teams, state.events, {for (final p in state.players) p.id: p.team});

  /// بيرجّع null لو اتسجّل، أو رسالة الخطأ. التبديل: [playerId] اللي نزل و[otherPlayerId] اللي طلع.
  Future<String?> addEvent(String playerId, String type, int? minute, {String? otherPlayerId}) async {
    if (!state.lineup.containsKey(playerId)) return 'اللاعب لازم يكون في التشكيلة (واحفظها الأول)';
    if (!kTestMode && DateTime.now().isBefore(match.dateTime.subtract(const Duration(minutes: 15)))) {
      return 'الأحداث بتتسجّل لما الماتش يبدأ';
    }
    try {
      await _events.addEvent(
        matchId: match.id,
        playerId: playerId,
        type: type,
        minute: minute,
        otherPlayerId: otherPlayerId,
      );
    } catch (e) {
      return dbMessage(e, fallback: 'تعذّر تسجيل الحدث');
    }
    // إشعار الحدث لمتابعين الماتش بيتبعت من الداتابيز لوحده
    await _reloadEvents();
    return null;
  }

  Future<void> removeEvent(String id) async {
    await _events.deleteEvent(id);
    await _reloadEvents();
  }

  Future<void> _reloadEvents() async {
    final events = await _events.fetchByMatch(match.id);
    emit(state.copyWith(events: events));
  }

  Player? player(String id) => _player(id);

  String playerName(String id) {
    for (final p in state.players) {
      if (p.id == id) return p.name;
    }
    return '—';
  }
}
