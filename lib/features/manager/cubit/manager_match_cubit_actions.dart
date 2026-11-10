part of 'manager_match_cubit.dart';

extension ManagerMatchCubitSections1 on ManagerMatchCubit {
  Future<void> load() async {
    _emit(ManagerMatchState(status: ManagerMatchStatus.loading, format: state.format));
    try {
      final players = await _players.fetchByTeams(match.teams);
      final events = await _events.fetchByMatch(match.id);
      final lineup = await _lineups.fetchForMatch(match.id);
      _emit(
        ManagerMatchState(
          status: ManagerMatchStatus.ready,
          players: players,
          events: events,
          lineup: {for (final l in lineup) l.playerId: l.status},
          format: state.format,
        ),
      );
    } catch (_) {
      _emit(ManagerMatchState(status: ManagerMatchStatus.ready, format: state.format));
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

  /// لاعب جديد لفريق في الماتش. [photo] اختياري (لو الرفع فشل اللاعب بيفضل من غير صورة).
  Future<void> addPlayerToTeam(
    String name,
    String team,
    String position, {
    String? nickname,
    Uint8List? photo,
    String? photoExt,
  }) async {
    final id = await _players.addPlayer(name: name, team: team, position: position, nickname: nickname);
    if (photo != null) {
      await _players.uploadPhoto(id, photo, photoExt ?? 'jpg').catchError((_) => '');
    }
    final players = await _players.fetchByTeams(match.teams);
    _emit(state.copyWith(players: players));
  }

  /// (مدير) حذف لاعب من الفريق خالص (لو لسه ملعبش) — بيرجّع رسالة خطأ أو null.
  Future<String?> deletePlayer(String id) async {
    try {
      final n = await _players.deletePlayers([id]);
      if (n == 0) return 'اللاعب ده لعب واتسجّل له أحداث — شيله من التشكيلة بس، أو كلّم الإدارة';
      final players = await _players.fetchByTeams(match.teams);
      _emit(state.copyWith(players: players, lineup: Map.of(state.lineup)..remove(id)));
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
    _emit(state.copyWith(lineup: map));
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
}
